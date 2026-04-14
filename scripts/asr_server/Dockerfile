# Utiliser Micromamba pour éviter les problèmes de compilation binaire
FROM mambaorg/micromamba:latest

USER root
RUN apt-get update && apt-get install -y \
    libsndfile1 \
    ffmpeg \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Création de l'environnement avec les paquets critiques déjà compilés
RUN micromamba install -y -n base -c conda-forge \
    python=3.10 \
    "numpy<2.0.0" \
    cython \
    youtokentome \
    "pyarrow<15.0.0" \
    datasets \
    setuptools \
    && micromamba clean --all --yes

# Passer sur l'environnement par défaut
ARG MAMBA_DOCKERFILE_ACTIVATE=1

# Installer les dépendances Python restantes
COPY requirements.txt .
# Nettoyage agressif du requirements.txt pour ne laisser que le strict nécessaire à pip
RUN sed -i '/numpy/d' requirements.txt && \
    sed -i '/Cython/d' requirements.txt && \
    sed -i '/youtokentome/d' requirements.txt && \
    sed -i '/pyarrow/d' requirements.txt && \
    sed -i '/datasets/d' requirements.txt

# On installe explicitement PyTorch pour CPU d'abord pour gagner en espace et en stabilité
RUN pip install --no-cache-dir torch==2.1.2+cpu --index-url https://download.pytorch.org/whl/cpu
RUN pip install --no-cache-dir "setuptools<70.0.0" "numpy<2.0.0" wheel && \
    pip install --no-cache-dir -r requirements.txt "numpy<2.0.0"

# Dossier modèle et script
RUN mkdir -p /app/models
COPY server_asr.py .

EXPOSE 7860
# Lancer avec micromamba-run pour être dans l'environnement
CMD ["micromamba", "run", "-n", "base", "python", "server_asr.py"]
