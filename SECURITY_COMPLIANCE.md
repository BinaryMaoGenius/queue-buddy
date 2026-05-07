# Rapport de Conformité Sécurité : Queue Buddy

Ce document détaille comment la solution **Queue Buddy** s'aligne sur les normes de sécurité internationales requises pour le secteur bancaire.

## 1. OWASP Top 10 (Sécurité des Applications)
L'implémentation actuelle traite plusieurs risques critiques identifiés par l'OWASP :

*   **A01:2021-Broken Access Control** : 
    *   Les `firestore.rules` ont été durcies pour interdire le listing public des tickets et clients.
    *   Accès granulaire : Seuls les agents authentifiés avec le rôle approprié peuvent voir les informations personnelles (PII).
*   **A02:2021-Cryptographic Failures** :
    *   Toutes les communications (Firebase, API ASR) passent par **HTTPS/TLS 1.2+**.
    *   Données au repos : Firestore utilise le chiffrement AES-256 par défaut.
*   **A04:2021-Insecure Design** :
    *   Séparation stricte entre le Frontend, le Backend (BaaS) et les microservices d'IA (ASR).
    *   Le système d'estimation dynamique évite les "rejets de service" ou la frustration client par des données erronées.

## 2. Protection des Données (RGPD / APDP)
Le projet respecte les principes de protection de la vie privée dès la conception (*Privacy by Design*) :

*   **Minimisation des données** : Seuls le nom et le téléphone sont collectés.
*   **Souveraineté des données** : Possibilité de déploiement **On-Premise** (via Docker) pour garantir que la voix des clients ne quitte jamais l'infrastructure de la banque.
*   **Isolation des PII** : L'audio envoyé aux serveurs de transcription ne contient pas d'identifiant nominatif lié dans la requête.

## 3. Normes Bancaires Spécifiques (PCI DSS / CPI)
*   **Traçabilité** : Chaque appel client et validation de ticket est horodaté et enregistré, permettant un audit complet des flux en agence.
*   **Sécurisation des Terminaux** : L'application Windows peut être verrouillée via des politiques de groupe (GPO) et l'accès au Back-office est protégé par un PIN (à migrer vers MFA pour la prod).

## 4. Recommandations pour la Mise en Production
Pour atteindre une certification bancaire complète (audit de sécurité de niveau 1) :

1.  **Authentification Forte (MFA)** : Remplacer le PIN simple par une authentification via Azure Active Directory (MSAL) ou Firebase Auth avec MFA.
2.  **App Check** : Activer **Firebase App Check** pour rejeter tout trafic ne provenant pas de l'application officielle d'Orabank.
3.  **WAF (Web Application Firewall)** : Déployer un Azure Front Door ou un WAF devant les API de reconnaissance vocale.
4.  **Audit Logs** : Activer les logs d'audit détaillés dans Google Cloud / Azure pour surveiller chaque lecture de donnée sensible.

---
**Statut actuel** : La solution est **"Security-Ready"** pour un pilote en agence, avec une architecture permettant une montée en charge vers les standards les plus stricts.
