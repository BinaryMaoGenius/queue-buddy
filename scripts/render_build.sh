#!/bin/bash

# Arrêter le script en cas d'erreur
set -e

echo "--- 🚀 Démarrage du build pour Render (Mode Verbeux Actif) ---"

# --- 📊 Diagnostic Système ---
echo "--- 🖥️ Infos Système ---"
free -h || echo "Commande 'free' non disponible"
df -h .
echo "Utilisateur actuel : $(whoami)"
echo "Dossier actuel : $(pwd)"

# --- ⚙️ Optimisation de la mémoire ---
export MALLOC_ARENA_MAX=2
export NODE_OPTIONS="--max-old-space-size=2048"
echo "MALLOC_ARENA_MAX réglé sur $MALLOC_ARENA_MAX"

# --- 🐦 Configuration de Flutter ---
FLUTTER_CHANNEL="stable"

if [ ! -d "flutter" ]; then
  echo "--- 📥 Téléchargement de Flutter ($FLUTTER_CHANNEL) ---"
  git clone https://github.com/flutter/flutter.git -b $FLUTTER_CHANNEL --depth 1
else
  echo "--- ✨ Flutter déjà présent, mise à jour (pull)... ---"
  cd flutter && git pull && cd ..
fi

# Ajouter Flutter au PATH
export PATH="$(pwd)/flutter/bin:$PATH"

# --- 🛠️ Préparation de Flutter ---
echo "--- 🛠️ Diagnostic Flutter ---"
flutter doctor -v

echo "--- 🌐 Activation du Web ---"
flutter config --enable-web

# --- 📦 Dépendances ---
echo "--- 📦 Récupération des dépendances (Verbeux) ---"
flutter pub get -v

# --- 🏗️ Build Web ---
echo "--- 🏗️ Construction de l'application Web (Mode Verbeux) ---"
# On ajoute le flag -v à flutter build pour un maximum de détails si ça plante
flutter build web --release -v \
  --no-tree-shake-icons \
  --dart-define=HF_TOKEN=$HF_TOKEN \
  --dart-define=ASR_SPACE_URL=$ASR_SPACE_URL \
  --dart-define=DJELIA_API_KEY=$DJELIA_API_KEY

echo "--- 📂 Vérification du dossier de sortie ---"
ls -lah build/web

echo "--- ✅ Build terminé avec succès ! ---"
