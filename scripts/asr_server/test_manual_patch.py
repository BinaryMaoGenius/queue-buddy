import os
import tarfile
import tempfile
import torch
from omegaconf import OmegaConf
import nemo.collections.asr as nemo_asr
from nemo.collections.asr.models.hybrid_rnnt_ctc_bpe_models import EncDecHybridRNNTCTCBPEModel

MODEL_PATH = "c:/Users/USER/queue-buddy/mon_modele_soloni/soloni-114m-tdt-ctc-v3.nemo"

def load_with_manual_patch(nemo_path):
    with tempfile.TemporaryDirectory() as tmpdir:
        print(f"Extracting {nemo_path} to {tmpdir}...")
        with tarfile.open(nemo_path, "r") as tar:
            tar.extractall(path=tmpdir)
        
        config_path = os.path.join(tmpdir, "model_config.yaml")
        conf = OmegaConf.load(config_path)
        
        # --- PATCH CONFIG ---
        OmegaConf.set_struct(conf, False)
        # Remove training/validation data parts to avoid abstract method errors
        if 'train_ds' in conf: del conf['train_ds']
        if 'validation_ds' in conf: del conf['validation_ds']
        if 'test_ds' in conf: del conf['test_ds']
        
        # Patch the specific greedy decoding error
        if 'decoding' in conf and 'greedy' in conf.decoding and 'boosting_tree' in conf.decoding.greedy:
             if 'key_phrase_items_list' in conf.decoding.greedy.boosting_tree:
                 del conf.decoding.greedy.boosting_tree['key_phrase_items_list']
        
        print("Config patched.")
        
        # --- MONKEY PATCH ASRModel ---
        def mock_setup(self, cfg): pass
        original_setup_train = nemo_asr.models.ASRModel.setup_training_data
        nemo_asr.models.ASRModel.setup_training_data = mock_setup
        nemo_asr.models.ASRModel.setup_validation_data = mock_setup
        nemo_asr.models.ASRModel.setup_test_data = mock_setup

        # --- INSTANTIATE ---
        # Note: We use the specific class to be sure
        print("Instantiating model from config...")
        model = EncDecHybridRNNTCTCBPEModel.from_config_dict(conf)
        
        # --- LOAD WEIGHTS ---
        ckpt_path = os.path.join(tmpdir, "model_weights.ckpt")
        print(f"Loading weights from {ckpt_path}...")
        state_dict = torch.load(ckpt_path, map_location='cpu')
        model.load_state_dict(state_dict, strict=False)
        
        print("Model loaded successfully!")
        return model

if __name__ == "__main__":
    try:
        model = load_with_manual_patch(MODEL_PATH)
        # Test a transcription if model is valid
        print("Transcription test...")
        # (Add transcription test here if needed)
    except Exception as e:
        print(f"Execution failed: {e}")
        import traceback
        traceback.print_exc()
