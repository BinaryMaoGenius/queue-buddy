# Script de configuration de l'environnement Python pour Soloni ASR

Write-Host "--- Configuration de l'environnement Soloni ASR ---" -ForegroundColor Cyan

# 1. Vérification de Python
if (!(Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Error "Python n'est pas installé ou n'est pas dans le PATH."
    exit 1
}

# 2. Création de l'environnement virtuel
if (!(Test-Path "venv")) {
    Write-Host "Création de l'environnement virtuel (venv)..."
    python -m venv venv
}

# 3. Activation et Installation des dépendances
Write-Host "Installation des dépendances (cela peut prendre quelques minutes)..."
.\venv\Scripts\pip install --upgrade pip
.\venv\Scripts\pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
.\venv\Scripts\pip install Cython
.\venv\Scripts\pip install -r requirements.txt

Write-Host "`n--- Installation terminée ! ---" -ForegroundColor Green
Write-Host "Pour lancer le serveur : .\venv\Scripts\python server_asr.py" -ForegroundColor Yellow
