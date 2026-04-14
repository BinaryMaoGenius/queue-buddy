#!/usr/bin/env pwsh
# ============================================================
#  deploy.ps1 - Script de déploiement automatique Queue-Buddy
#  Usage: .\deploy.ps1
#  Usage avec message: .\deploy.ps1 -Message "Ma description"
# ============================================================

param(
    [string]$Message = "deploy: mise à jour de l'application"
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   SIRA Queue-Buddy - Déploiement Auto    ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# 1. Trouver Flutter
$FlutterPath = $null
$candidates = @(
    "flutter",
    "$env:USERPROFILE\flutter\bin\flutter",
    "$env:LOCALAPPDATA\flutter\bin\flutter",
    "C:\flutter\bin\flutter",
    "C:\src\flutter\bin\flutter"
)
foreach ($c in $candidates) {
    if (Get-Command $c -ErrorAction SilentlyContinue) {
        $FlutterPath = $c
        break
    }
}

if (-not $FlutterPath) {
    Write-Host "❌ Flutter introuvable ! Ajoutez Flutter à votre PATH." -ForegroundColor Red
    exit 1
}

Write-Host "✅ Flutter trouvé : $FlutterPath" -ForegroundColor Green

# 2. Lire le token HF depuis .env
$HfToken = $env:HF_TOKEN
if (-not $HfToken -and (Test-Path ".env")) {
    $envContent = Get-Content ".env" | Where-Object { $_ -match "^HF_TOKEN=" }
    if ($envContent) {
        $HfToken = $envContent -replace "^HF_TOKEN=", ""
        Write-Host "✅ HF_TOKEN chargé depuis .env" -ForegroundColor Green
    }
}
if (-not $HfToken) {
    Write-Host "⚠️  HF_TOKEN non trouvé. Le modèle Soloni fonctionnera en mode dégradé." -ForegroundColor Yellow
    $HfToken = ""
}

# 3. Compilation Flutter Web
Write-Host ""
Write-Host "━━━ ÉTAPE 1/3 : Compilation Flutter Web ━━━" -ForegroundColor Yellow

$buildArgs = @(
    "build", "web", "--release",
    "--no-tree-shake-icons",
    "--dart-define=ASR_SPACE_URL=https://binaryMao-sira-asr.hf.space/transcribe"
)
if ($HfToken) {
    $buildArgs += "--dart-define=HF_TOKEN=$HfToken"
}

& $FlutterPath @buildArgs
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Compilation échouée !" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Compilation réussie !" -ForegroundColor Green

# 4. Copier dans deploy/web
Write-Host ""
Write-Host "━━━ ÉTAPE 2/3 : Copie vers deploy/web ━━━" -ForegroundColor Yellow

if (Test-Path "deploy\web") {
    Remove-Item -Recurse -Force "deploy\web"
}
New-Item -ItemType Directory -Force -Path "deploy\web" | Out-Null
Copy-Item -Path "build\web\*" -Destination "deploy\web\" -Recurse -Force
Write-Host "✅ Fichiers copiés dans deploy/web !" -ForegroundColor Green

# 5. Git Push
Write-Host ""
Write-Host "━━━ ÉTAPE 3/3 : Publication sur GitHub ━━━" -ForegroundColor Yellow

git add deploy/ render_build.sh 2>&1 | Out-Null
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
git commit -m "$Message [$timestamp]" 2>&1
git push origin main 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  Erreur lors du push. Vérifiez votre connexion." -ForegroundColor Yellow
} else {
    Write-Host "✅ Push réussi !" -ForegroundColor Green
}

Write-Host ""
Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║   ✅ DÉPLOIEMENT TERMINÉ AVEC SUCCÈS !   ║" -ForegroundColor Green
Write-Host "╠══════════════════════════════════════════╣" -ForegroundColor Green
Write-Host "║  Render va mettre à jour automatiquement ║" -ForegroundColor Green
Write-Host "║  en servant les fichiers deploy/web/     ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
