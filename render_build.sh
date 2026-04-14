#!/bin/bash
# Les fichiers web sont pré-compilés et disponibles dans le dossier deploy/web
# Render sert directement ce dossier - pas besoin de recompiler
echo "==> Fichiers web pré-compilés détectés dans deploy/web"
echo "==> Publication directe sans recompilation Flutter"
ls -la deploy/web/ | head -20
echo "==> Prêt à servir !"
