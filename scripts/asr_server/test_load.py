import nemo.collections.asr as nemo_asr
import torch
import os

MODEL_PATH = "c:/Users/USER/queue-buddy/mon_modele_soloni/soloni-114m-tdt-ctc-v3.nemo"

print(f"Testing load from: {MODEL_PATH}")
if not os.path.exists(MODEL_PATH):
    print("Error: File not found!")
    exit(1)

try:
    print("Attempt 1: Generic ASRModel.restore_from")
    model = nemo_asr.models.ASRModel.restore_from(MODEL_PATH, map_location=torch.device('cpu'))
    print("Success Attempt 1")
except Exception as e:
    print(f"Failed Attempt 1: {e}")

try:
    print("\nAttempt 2: EncDecCTCModelBPE.restore_from with strict=False")
    from nemo.collections.asr.models import EncDecCTCModelBPE
    model = EncDecCTCModelBPE.restore_from(MODEL_PATH, map_location=torch.device('cpu'), strict=False)
    print("Success Attempt 2")
except Exception as e:
    print(f"Failed Attempt 2: {e}")

try:
    print("\nAttempt 3: Manual config override")
    from nemo.core.classes import ModelPT
    from omegaconf import OmegaConf
    # We try to extract and modify config
    import tarfile
    import tempfile
    with tempfile.TemporaryDirectory() as tmpdir:
        with tarfile.open(MODEL_PATH, 'r:gz') as tar:
            tar.extract('model_config.yaml', path=tmpdir)
            conf = OmegaConf.load(os.path.join(tmpdir, 'model_config.yaml'))
            # Force remove training data config
            if 'train_ds' in conf: del conf['train_ds']
            if 'validation_ds' in conf: del conf['validation_ds']
            # Re-instantiate from specific class if possible
            # This is complex, but let's see if we can get past abstract method error
            print("Config loaded and cleaned.")
except Exception as e:
    print(f"Failed Attempt 3: {e}")
