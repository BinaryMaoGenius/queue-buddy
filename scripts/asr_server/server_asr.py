import uvicorn
from fastapi import FastAPI, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
import torch
import os
import tempfile
import librosa
import soundfile as sf
import numpy as np
from huggingface_hub import hf_hub_download
from omegaconf import OmegaConf

# Configuration du modèle et du Repo HF
REPO_ID = "RobotsMali/soloni-114m-tdt-ctc-v3"
MODEL_FILENAME = "soloni-114m-tdt-ctc-v3.nemo"

# Chemins locaux
MODEL_DIR = os.environ.get("MODEL_DIR", "models")
MODEL_PATH = os.path.join(MODEL_DIR, MODEL_FILENAME)

# Import NeMo components (lazily imported in load_model to avoid boot lag)
import nemo.collections.asr as nemo_asr
from nemo.core.classes import ModelPT
from nemo.collections.asr.models.hybrid_rnnt_ctc_bpe_models import EncDecHybridRNNTCTCBPEModel

app = FastAPI(title="Soloni ASR Production Server")

# Configuration CORS pour autoriser l'accès depuis l'app Flutter
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- MONKEY PATCHING (Indispensable pour charger le modèle sans datasets) ---
def mock_setup(self, cfg=None): pass

print("[BOOT] Application des correctifs de compatibilité...")

import abc
abc.ABC.__init_subclass__ = classmethod(lambda cls, **kwargs: None)

for cls in [ModelPT, nemo_asr.models.ASRModel, EncDecHybridRNNTCTCBPEModel]:
    cls.setup_training_data = mock_setup
    cls.setup_validation_data = mock_setup
    cls.setup_test_data = mock_setup
    cls.__abstractmethods__ = frozenset()

import omegaconf
_orig_getattr = omegaconf.dictconfig.DictConfig.__getattr__

def patched_getattr(self, key):
    try:
        return _orig_getattr(self, key)
    except omegaconf.errors.ConfigAttributeError as e:
        if key == "key_phrase_items_list":
            return None
        raise

omegaconf.dictconfig.DictConfig.__getattr__ = patched_getattr

import nemo.collections.asr.parts.utils.asr_confidence_utils as conf_utils
_old_conf_init = conf_utils.ConfidenceConfig.__init__
def _new_conf_init(self, *args, **kwargs):
    kwargs.pop('tdt_include_duration', None)
    _old_conf_init(self, *args, **kwargs)
conf_utils.ConfidenceConfig.__init__ = _new_conf_init

asr_model = None
loading_error = None

def load_model():
    global asr_model, loading_error
    
    if not os.path.exists(MODEL_PATH):
        print(f"[BOOT] Modèle introuvable localement. Téléchargement depuis {REPO_ID}...")
        try:
            os.makedirs(MODEL_DIR, exist_ok=True)
            downloaded_path = hf_hub_download(
                repo_id=REPO_ID, 
                filename=MODEL_FILENAME,
                local_dir=MODEL_DIR,
                token=os.environ.get("HF_TOKEN")
            )
            print(f"[BOOT] Téléchargement terminé : {downloaded_path}")
            
        except Exception as e:
            loading_error = f"Échec du téléchargement HF : {e}"
            print(f"[CRITICAL] {loading_error}")
            return

    # 2. Charger le modèle NeMo
    print(f"[BOOT] Chargement du modèle Soloni depuis : {MODEL_PATH}")
    try:
        # ASRModel.restore_from détecte automatiquement la classe (CTC, RNNT ou Hybrid)
        asr_model = nemo_asr.models.ASRModel.restore_from(
            MODEL_PATH, 
            map_location=torch.device("cpu")
        )
        asr_model.eval()
        try:
            asr_model.change_decoding_strategy(decoder_type="ctc")
            print("[BOOT] Mode CTC activé.")
        except: pass
        print("[BOOT] Modèle chargé avec succès !")
    except Exception as e:
        import traceback
        loading_error = f"{e} - Trace: {traceback.format_exc()}"
        print(f"[CRITICAL] Échec du chargement : {loading_error}")

@app.on_event("startup")
async def startup_event():
    load_model()

@app.get("/")
async def root():
    return {
        "app": "Soloni ASR Server", 
        "status": "online", 
        "model_loaded": asr_model is not None,
        "error": str(loading_error) if loading_error else None
    }

@app.post("/transcribe")
async def transcribe(file: UploadFile = File(...)):
    if asr_model is None:
        return {"error": "Modèle non chargé", "status": "error"}

    with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as tmp_audio:
        content = await file.read()
        tmp_audio.write(content)
        tmp_path = tmp_audio.name

    try:
        audio, _ = librosa.load(tmp_path, sr=16000, mono=True)
        clean_path = tmp_path.replace(".wav", "_clean.wav")
        sf.write(clean_path, audio, 16000)
        
        result = asr_model.transcribe([clean_path])
        text = result[0] if isinstance(result, list) and result else ""
        return {"text": text, "status": "success"}
    except Exception as e:
        print(f"[RUNTIME ERROR] {e}")
        return {"error": str(e), "status": "error"}
    finally:
        if os.path.exists(tmp_path): os.remove(tmp_path)
        if 'clean_path' in locals() and os.path.exists(clean_path): os.remove(clean_path)

@app.get("/health")
async def health():
    return {"status": "ready" if asr_model else "loading"}

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port)
