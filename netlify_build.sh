#!/bin/bash

# Configuration
FLUTTER_CHANNEL="stable"
FLUTTER_VERSION="3.24.0" # Version spécifique pour la stabilité

echo "--- Démarrage de l'installation de Flutter ---"

# 1. Cloner Flutter si non présent
if [ ! -d "flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b $FLUTTER_CHANNEL
fi

# 2. Ajouter Flutter au PATH (au début pour priorité)
export PATH="`pwd`/flutter/bin:$PATH"

# 3. Préparer Flutter
flutter doctor -v
flutter config --enable-web

# 4. Récupérer les dépendances
flutter pub get

# 5. Build Web complet (Force HTML renderer pour éviter les pages blanches CanvasKit)
flutter build web --release \
  --web-renderer html \
  --dart-define=HF_TOKEN=$HF_TOKEN \
  --dart-define=ASR_SPACE_URL=$ASR_SPACE_URL

echo "--- Build terminé ---"
