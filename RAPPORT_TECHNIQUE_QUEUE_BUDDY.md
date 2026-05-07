# Rapport Technique : Queue Buddy

Ce document détaille l'architecture logicielle, les choix technologiques et les flux de données du projet **Queue Buddy**.

## 1. Stack Technologique & Dépendances
Le projet est développé autour d'un socle **Flutter (Dart 3.x)** et **Firebase**, complété par des services cognitifs en **Python**.

### 1.1 Frontend (Flutter)
- **Gestion d'état :** Utilisation du package `provider` pour l'injection de dépendances et la gestion réactive de l'état (ex: `FirebaseService`).
- **Persistance locale :** `shared_preferences` pour sauvegarder l'historique des tickets pris par l'utilisateur sur son appareil.
- **UI / UX :** 
  - `google_fonts` pour la typographie (modernisation de l'interface).
  - `flutter_animate` pour les micro-animations (transitions de pages, apparition des tickets).
  - `fl_chart` pour les graphiques du back-office d'analyse (`analytics_page.dart`).
- **Génération de documents :** `qr_flutter` (pour générer les QR Codes de suivi), `screenshot` (pour capturer les widgets), `pdf` et `printing` (pour la génération et l'impression thermique ou A4 des tickets physiques).

### 1.2 Accessibilité & Matériel (Borne)
- **Audio & Voix :** 
  - `record` pour capturer l'audio depuis le microphone de la borne.
  - `audioplayers` pour la lecture des fichiers audio générés par le Text-to-Speech (TTS) ou les bips système.
  - `flutter_tts` utilisé en fallback ou en complément pour le guidage vocal natif de l'OS.

### 1.3 Backend & Cloud (Firebase)
- **Base de données :** `cloud_firestore` (NoSQL). Le projet implémente un système de **Mocking** (bascule via `_useMock` dans `FirebaseService`) qui permet un développement hors-ligne et des démonstrations instantanées sans configurer Firebase.
- **Notifications :** `firebase_messaging` et `flutter_local_notifications`. Permet d'alerter le client via une notification Push (`subscribeToTicketTopic('ticket_$ticketId')`) lorsque son tour approche.

## 2. Architecture des Microservices IA (ASR & NLU)
La reconnaissance vocale en langues locales (Bambara/Français) est gérée par une logique hybride (Djelia Cloud / Serveur Local / Hugging Face Spaces).

### 2.1 Moteur NLU & Intentions (`soloba_service.dart`)
- **Principe :** Transforme la transcription textuelle brute en **Action Métier** (`versement`, `retrait`, `virement`, `renseignement`).
- **Algorithme Hybride :**
  1. **IA Sémantique :** Appel à l'API d'inférence de Hugging Face (`mDeBERTa-v3-base-mnli-xnli`) pour effectuer du *Zero-Shot Classification*. 
  2. **Fallback Regex / Mots-clés :** Si l'IA échoue (latence, offline, score de confiance < 60%), le système bascule sur un algorithme local d'analyse de sous-chaînes normalisées pondérées (ex: "wari don" = +1.5 points pour `versement`).

### 2.2 Serveur ASR Dédié (`scripts/asr_server/server_asr.py`)
Un serveur d'inférence Python (FastAPI) est fourni pour héberger le modèle ASR localement et garantir la **confidentialité des données** (On-Premise).
- **Frameworks :** `FastAPI`, `uvicorn`, `torch`, `librosa`.
- **Modèle Acoustique :** `RobotsMali/soloni-114m-tdt-ctc-v3` (Architecture NeMo NVIDIA : EncDecHybridRNNTCTCBPEModel).
- **Traitement du signal :** Resampling à `16000Hz` mono forcé en amont du décodeur (via `soundfile`).
- **Optimisation :** Monkey patching dynamique (`ModelPT.setup_training_data = mock_setup`) appliqué au démarrage pour shunter les dépendances liées à l'entraînement, allégeant la consommation de RAM en pure inférence.

## 3. Modélisation des Données (Firestore)
Le schéma NoSQL est structuré autour des collections suivantes :

- **`agences` :** Contient la configuration (localisation, `enAttenteCount`, etc.).
- **`clients` :** Historisation des profils (`id`, `nom`, `tel`, pour l'auto-complétion).
- **`tickets` :** Contient le cycle de vie de la file d'attente.
  - *Champs notables :* `numeroTicket` (ex: "A-102"), `statut` (`enAttente`, `appele`, `valide`), `position` (position dynamique mise à jour en temps réel via transactions).
- **`agence_counters` :** Document utilisé dans des **Transactions Firestore (`runTransaction`)** pour gérer l'incrémentation atomique du numéro de ticket (`last_ticket_number`) et éviter les conflits de concurrence si deux bornes prennent un ticket à la même milliseconde.

## 4. Workflows et Transactions
### 4.1 Prise de Ticket (`prendreTicket`)
1. Le client parle à la borne, le modèle ASR renvoie le texte.
2. Le module NLU classe l'intention.
3. Appel à `FirebaseService.prendreTicket()`.
4. Exécution d'une transaction Firestore qui lit `agence_counters`, incrémente `last_ticket_number` et `waiting_count`, et met à jour `agences`.
5. Le ticket est créé, retourné à l'UI, et le QR Code / PDF est généré pour impression locale.

### 4.2 Appel au Guichet (`appelerSuivant`)
1. Le guichetier clique sur "Appeler suivant".
2. Transaction Firebase : le ticket le plus ancien passe au statut `appele`, `position: 0`, et `waiting_count` diminue.
3. Un batch Firestore (`_db.batch()`) est déclenché pour recalculer en bloc la `position` (1 à N) de tous les tickets restants en attente.
4. Une notification Cloud Messaging est envoyée au smartphone du client appelé.

## 6. Sécurité Avancée et Auditabilité
### 6.1 Conformité OWASP Top 10
Bien que le système soit hybride (Flutter/Python), nous appliquons les contrôles **OWASP** sur les vecteurs d'attaque critiques :
- **Injection de Commande Vocale :** Les transcriptions issues de l'ASR sont traitées comme des entrées non sécurisées. Avant d'être traitées par le module NLU ou d'être stockées en base, elles subissent une normalisation et un filtrage pour empêcher toute injection de scripts ou de commandes malveillantes.
- **Sécurisation des APIs :** Les échanges entre le frontend Flutter et le backend ASR (FastAPI) sont authentifiés via des secrets rotatifs et transportés exclusivement via TLS 1.3 (en mode cloud).

### 6.2 Traçabilité des Données et Risques liés aux GANs
Dans le cadre de l'utilisation de modèles génératifs (GAN) pour l'augmentation de données ou la simulation, la traçabilité est assurée par :
- **Digital Watermarking :** Insertion de signatures statistiques imperceptibles dans les poids des modèles ou les données générées. Cela permet, en cas de fuite, d'identifier formellement la source du modèle incriminé.
- **Détection d'Inférence (Membership Inference) :** Mise en place de protocoles d'audit réguliers pour s'assurer que le modèle n'a pas "mémorisé" de données réelles sensibles au-delà des patterns statistiques généraux.
- **Confidentialité Différentielle :** Application de mécanismes de bruitage lors de la phase de fine-tuning des modèles d'IA pour garantir mathématiquement qu'aucune donnée individuelle ne peut être extraite du modèle final.

### 6.3 Souveraineté et Déploiement On-Premise
Le déploiement via Docker sur l'infrastructure interne de la banque garantit que les flux audio (données biométriques sensibles) ne quittent jamais le périmètre de sécurité de l'institution, éliminant les risques liés au transit sur le réseau public.

## 7. Perspectives Techniques
- **Extension Multilingue :** Passage d'un modèle d'intention monolithique à une architecture de type *Mixture of Experts* pour supporter plus de 5 langues locales sans perte de précision.
- **Optimisation Edge :** Inférence locale directement sur la borne via TensorFlow Lite pour réduire la dépendance au réseau local.
