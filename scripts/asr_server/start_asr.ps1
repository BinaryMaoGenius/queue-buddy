# Script pour lancer le serveur ASR Soloni localement
# Utilise l'environnement virtuel Python existant

Write-Host "--- Dmarrage du serveur ASR Soloni Local ---" -ForegroundColor Cyan
Write-Host "Modle : soloni-114m-tdt-ctc-v3.nemo" -ForegroundColor Gray

$VENV_PATH = ".\venv\Scripts\python.exe"
$SERVER_SCRIPT = ".\server_asr.py"

if (!(Test-Path $VENV_PATH)) {
    Write-Host "ERREUR : Environnement virtuel (venv) introuvable." -ForegroundColor Red
    Write-Host "Veuillez d'abord excuter setup_env.ps1" -ForegroundColor Yellow
    exit
}

Write-Host "Initialisation du modle (cela peut prendre 30-60 secondes sur CPU)..." -ForegroundColor Yellow
& $VENV_PATH $SERVER_SCRIPT
