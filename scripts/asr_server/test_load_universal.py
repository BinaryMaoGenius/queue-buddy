import nemo.collections.asr as nemo_asr
import torch
import os

MODEL_DIR = "c:/Users/USER/queue-buddy/mon_modele_soloni"
MODEL_NAME = "soloni-114m-tdt-ctc-v3.nemo"
FULL_PATH = os.path.join(MODEL_DIR, MODEL_NAME)

print(f"Trying to load from: {FULL_PATH}")
try:
    # 1. Standard restore_from
    model = nemo_asr.models.ASRModel.restore_from(FULL_PATH, map_location=torch.device('cpu'))
    print("SUCCESS: restore_from worked.")
except Exception as e:
    print(f"FAILED: restore_from: {e}")

try:
    # 2. from_pretrained with local path
    model = nemo_asr.models.ASRModel.from_pretrained(model_name=MODEL_NAME, model_path=FULL_PATH)
    print("SUCCESS: from_pretrained worked.")
except Exception as e:
    print(f"FAILED: from_pretrained: {e}")

try:
    # 3. Specific class restore_from
    from nemo.collections.asr.models import EncDecHybridRNNTCTCBPEModel
    # Mocking abstract methods before
    EncDecHybridRNNTCTCBPEModel.setup_training_data = lambda self, cfg: None
    EncDecHybridRNNTCTCBPEModel.setup_validation_data = lambda self, cfg: None
    model = EncDecHybridRNNTCTCBPEModel.restore_from(FULL_PATH, map_location=torch.device('cpu'))
    print("SUCCESS: EncDecHybridRNNTCTCBPEModel.restore_from worked.")
except Exception as e:
    print(f"FAILED: EncDecHybridRNNTCTCBPEModel.restore_from: {e}")
