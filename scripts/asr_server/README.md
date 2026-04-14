---
title: Soloni ASR Sira
emoji: 🎙️
colorFrom: green
colorTo: yellow
sdk: docker
app_port: 8000
pinned: false
---

# Sira ASR Server (Soloni v3)
Serveur de reconnaissance vocale Bambara basé sur NeMo et FastAPI pour le projet Queue-Buddy.

## Structure
- `server_asr.py` : Code du serveur FastAPI (téléchargement auto via Hugging Face).
- `Dockerfile` : Instructions de build pour déploiement (Local ou HF Spaces).
- `requirements.txt` : Dépendances incluant `huggingface_hub`.

## Modèle utilisé
Source : [RobotsMali/soloni-114m-tdt-ctc-v3](https://huggingface.co/RobotsMali/soloni-114m-tdt-ctc-v3)
Le serveur télécharge automatiquement ce modèle au premier démarrage.

## Déploiement sur HF Spaces
Ce dossier est déjà configuré pour être déployé en tant que **Space Docker** sur Hugging Face.
- Port par défaut : 8000
- SDK : Docker
