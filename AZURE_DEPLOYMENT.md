# Guide de Déploiement : Queue Buddy sur Microsoft Azure & Windows

Ce guide explique comment déployer la solution **Queue Buddy** au sein de l'infrastructure d'Orabank, en respectant les exigences techniques (Windows/Azure).

## 1. Déploiement du Frontend (Flutter Web / Windows)

### 1.1. Azure App Service (Web)
Le moyen le plus simple de déployer l'interface client et back-office est d'utiliser **Azure App Service**.

1.  **Build** : Générez le bundle web.
    ```powershell
    flutter build web --release --dart-define=ASR_SPACE_URL="https://votre-serveur-asr.azurewebsites.net"
    ```
2.  **Déploiement** : Poussez le contenu du dossier `build/web` vers un App Service (Plan Linux ou Windows).
3.  **Configuration** : Configurez le HTTPS et le domaine personnalisé dans le portail Azure.

### 1.2. Application Desktop (Windows)
Pour les postes de travail des agents (Windows), compilez l'application nativement.

1.  **Build** :
    ```powershell
    flutter build windows --release
    ```
2.  **Distribution** : Le dossier `build/windows/runner/Release` contient l'exécutable `.exe` et les DLL nécessaires. Il peut être packagé via **MSIX** pour un déployement via Intune ou SCCM.

---

## 2. Déploiement du Backend IA (ASR/NLU Python)

Le DSI exige que la voix ne quitte pas le réseau ou soit hébergée de manière sécurisée.

### 2.1. Azure Container Instances (ACI)
Hébergez le serveur ASR (`scripts/asr_server`) dans un conteneur Docker sur Azure.

1.  **Build Image** :
    ```bash
    docker build -t queue-buddy-asr ./scripts/asr_server
    ```
2.  **Azure Container Registry (ACR)** : Poussez l'image vers votre registre privé Azure.
3.  **Déploiement ACI** : Lancez le conteneur sur ACI avec un accès GPU (si disponible) ou CPU optimisé.

### 2.2. Hébergement On-Premise (Windows Server)
Si la banque préfère garder les données en local :
1.  Installez **Docker Desktop** sur un serveur Windows.
2.  Utilisez le fichier `docker-compose.yml` fourni pour lancer le service ASR.
3.  Configurez le pare-feu Windows pour autoriser le trafic sur le port `8000`.

---

## 3. Sécurité & Conformité Azure

*   **Azure Key Vault** : Stockez les clés d'API (Firebase, Djelia, HF) dans Key Vault plutôt que dans les fichiers `.env`.
*   **Azure Active Directory (AAD)** : Intégrez l'authentification des agents avec le compte Microsoft de la banque (via `firebase_auth` supportant OIDC/SAML).
*   **Private Links** : Utilisez Azure Private Links pour que le frontend et le backend IA communiquent sans passer par l'internet public.

---

## 4. Maintenance
Les logs peuvent être centralisés dans **Azure Monitor** (Application Insights) pour un suivi en temps réel des performances et des erreurs de l'assistant vocal.
