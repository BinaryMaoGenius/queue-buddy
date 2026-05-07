# Rapport de Projet : Queue Buddy (Système Intelligent de Gestion de File d'Attente)

**À l'attention du Directeur des Systèmes d'Information (DSI)**

## 1. Résumé Exécutif
Le projet **Queue Buddy** est une solution innovante de gestion de file d'attente conçue spécifiquement pour le secteur bancaire. L'application vise à moderniser l'accueil en agence, optimiser les flux de clients, et surtout offrir une expérience utilisateur inclusive grâce à l'intégration poussée de l'intelligence artificielle (reconnaissance vocale et compréhension du langage naturel en langues locales, notamment le Bambara et le Français).

Le système se compose d'une borne interactive pour les clients, d'une interface de guichet pour les opérateurs, et d'un tableau de bord analytique pour les superviseurs.

## 2. Architecture Technique Globale
L'architecture de Queue Buddy s'appuie sur des technologies modernes, robustes et évolutives, divisées en trois grands blocs :

### 2.1. Frontend (Application Client & Guichet)
Développé avec le framework **Flutter** (Dart 3.x), permettant un déploiement multiplateforme (Tablette pour les bornes, Web/Desktop pour le back-office).
*   **Gestion d'état :** `provider` pour une architecture réactive.
*   **Design & UI :** `google_fonts` et `flutter_animate` pour une interface fluide, animée et moderne.
*   **Génération de tickets :** Intégration de `qr_flutter` pour les QR codes, `screenshot`, `pdf`, et `printing` pour la création et l'impression des tickets physiques ou virtuels.
*   **Accessibilité :** Synthèse vocale (`flutter_tts`) et guidage vocal (`voice_guide_controller.dart`) pour assister les personnes analphabètes ou malvoyantes.

### 2.2. Backend & Real-time Database (BaaS)
L'infrastructure serveur repose sur **Firebase**, garantissant une haute disponibilité et un passage à l'échelle automatique.
*   **Base de données :** Cloud Firestore (NoSQL temps réel) pour synchroniser instantanément l'état de la file d'attente entre les bornes et les guichets.
*   **Notifications :** Firebase Cloud Messaging (`firebase_messaging`) pour notifier les clients sur leur smartphone de l'avancée de la file.
*   **Règles de sécurité :** Implémentation stricte via `firestore.rules` et `storage.rules`.

### 2.3. Microservices IA (Speech-to-Text & NLU)
C'est le cœur d'innovation du projet. Le système est capable de comprendre la demande du client à la voix.
*   **Services (`soloba_service.dart` & `djelia_speech_service.dart`) :**
    *   **ASR (Automatic Speech Recognition) :** Modèles sur-mesure (Soloni-ASR v3-ctc / Djelia Cloud) spécialisés dans la reconnaissance du **Bambara** et du **Français**.
    *   **NLU (Natural Language Understanding) :** Modèle mDeBERTa pour la classification des intentions (Versement, Retrait, Virement, Renseignement) basé sur des requêtes vocales.
*   **Hébergement IA :** 
    *   Possibilité d'hébergement dans le Cloud (Hugging Face Spaces : `binaryMao-sira-asr.hf.space`).
    *   Possibilité d'hébergement sur site (On-Premise) via le serveur Python embarqué (`scripts/asr_server` / Dockerfile) pour garantir la **confidentialité des données bancaires**.

## 3. Fonctionnalités Clés

### Pour le Client (Borne Interactive)
*   **Prise de ticket intelligente :** Le client exprime son besoin vocalement ("N b'a fɛ ka wari don", "Je veux faire un retrait"). L'IA détecte l'intention et l'assigne à la bonne file.
*   **Impression et Digitalisation :** Génération d'un ticket physique ou scan d'un QR code pour un suivi sur mobile.
*   **Guidage vocal continu :** Interface entièrement vocalisée pour l'inclusivité.

### Pour l'Opérateur (Guichet - Backoffice)
*   **Interface d'appel :** Vue en temps réel de la file d'attente (`backoffice_page.dart`).
*   **Gestion des flux :** Appel des clients, mise en attente, clôture des opérations.

### Pour le Management (Supervision)
*   **Tableau de bord (Admin Dashboard) :** Supervision globale de l'agence.
*   **Analytiques (`analytics_page.dart`) :** Graphiques (`fl_chart`) sur les temps d'attente moyens, la durée des traitements par guichet, et les motifs de visite les plus fréquents.
*   **Historique :** Traçabilité complète des opérations (`history_page.dart`).

## 4. Sécurité et Conformité
*   **Absence de PII dans le Cloud IA :** L'audio envoyé aux services de transcription ne contient pas de données nominatives. La possibilité de déployer le serveur ASR en local (`Docker` / Python backend) garantit que la voix ne quitte jamais le réseau de la banque.
*   **Sécurité Firebase :** Les règles Firestore sont configurées pour bloquer les accès non autorisés, assurant l'intégrité de la base de données.
*   **Environnement protégé :** Les clés d'API (comme `DJELIA_API_KEY`) sont passées via des variables d'environnement (`--dart-define` / fichier `.env`) et ne sont pas codées en dur.

## 5. Déploiement et Opérations (DevOps)
*   **Conteneurisation IA :** Le moteur de reconnaissance vocale dispose de son propre `Dockerfile` et fichier `docker_compose.yml`, prêt à être déployé sur les serveurs de la banque.
*   **Scripts d'automatisation :** Présence de scripts PowerShell (`setup_env.ps1`, `start_asr.ps1`) pour configurer rapidement les environnements sous Windows.
*   **CI/CD :** Le projet est structuré pour s'intégrer facilement aux pipelines de CI/CD classiques (GitHub Actions potentiellement).

## 6. Conclusion et Avantage Compétitif
Queue Buddy n'est pas un simple gestionnaire de file. C'est un outil d'**Inclusion Financière**. En permettant aux clients, même analphabètes, d'interagir naturellement dans leur langue maternelle avec les systèmes de la banque, l'institution renforce sa proximité client et fluidifie l'accueil en agence. L'architecture hybride (Cloud Firebase / IA locale ou dédiée) permet un compromis idéal entre scalabilité, innovation et sécurité bancaire.
