# Script de secours pour installer Python 3.12 et NeMo via Micromamba

Write-Host "--- Correction de l'environnement Python (Solution Micromamba) ---" -ForegroundColor Cyan

$micromamba_url = "https://micro.mamba.pm/api/micromamba/win-64/latest"
$dest_exe = ".\micromamba.exe"

# 1. Télécharger Micromamba si non présent
if (!(Test-Path $dest_exe)) {
    Write-Host "Téléchargement de Micromamba..."
    Invoke-WebRequest -Uri $micromamba_url -OutFile "micromamba.tar.bz2"
    # Note: L'API micromamba renvoie souvent un .exe directement sous forme de bz2 ou zip sur Win
    # Mais sur Windows, le plus simple est le lien direct vers l'exécutable
    Invoke-WebRequest -Uri "https://github.com/mamba-org/micromamba-releases/releases/latest/download/micromamba-win-64" -OutFile $dest_exe
}

# 2. Créer l'environnement Python 3.12
Write-Host "Création de l'environnement Python 3.12 (soloni_env)..."
.\micromamba.exe create -n soloni_env -c conda-forge python=3.12 -y --prefix .\env_312

# 3. Installer les dépendances dans cet environnement
Write-Host "Installation de PyTorch et NeMo (cela peut prendre quelques minutes)..."
.\micromamba.exe install -p .\env_312 -c conda-forge -c pytorch -c nvidia pytorch cpuonly -y
.\micromamba.exe run -p .\env_312 pip install nemo_toolkit[asr] fastapi uvicorn librosa pydub python-multipart

Write-Host "`n--- Correction terminée ! ---" -ForegroundColor Green
Write-Host "Pour lancer le serveur : .\micromamba.exe run -p .\env_312 python server_asr.py" -ForegroundColor Yellow
