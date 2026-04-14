import zipfile
import os
import tempfile
import shutil
from omegaconf import OmegaConf

ORIGINAL_NEMO = "c:/Users/USER/queue-buddy/mon_modele_soloni/soloni-114m-tdt-ctc-v3.nemo"
FIXED_NEMO = "c:/Users/USER/queue-buddy/mon_modele_soloni/soloni_fixed.nemo"

def fix_nemo_config(original_path, fixed_path):
    print(f"Fixing {original_path} -> {fixed_path}")
    with tempfile.TemporaryDirectory() as tmpdir:
        # 1. Extract everything
        with zipfile.ZipFile(original_path, 'r') as zip_ref:
            zip_ref.extractall(tmpdir)
        
        # 2. Patch model_config.yaml
        config_path = os.path.join(tmpdir, 'model_config.yaml')
        if not os.path.exists(config_path):
            # Try to find it if nested
            for root, dirs, files in os.walk(tmpdir):
                if 'model_config.yaml' in files:
                    config_path = os.path.join(root, 'model_config.yaml')
                    break
        
        print(f"Loading config from {config_path}")
        conf = OmegaConf.load(config_path)
        
        # Disable struct mode in the object
        OmegaConf.set_struct(conf, False)
        
        # Nuke the offending key
        try:
            if 'decoding' in conf and 'greedy' in conf.decoding and 'boosting_tree' in conf.decoding.greedy:
                 if 'key_phrase_items_list' in conf.decoding.greedy.boosting_tree:
                     print("Removing 'key_phrase_items_list'...")
                     del conf.decoding.greedy.boosting_tree['key_phrase_items_list']
        except Exception as e:
            print(f"Warning during patch: {e}")
            
        # Add global _struct_: false if possible
        conf['_struct_'] = False
        
        # Save patched config
        OmegaConf.save(conf, config_path)
        print("Config patched and saved.")
        
        # 3. Create NEW ZIP
        with zipfile.ZipFile(fixed_path, 'w', compression=zipfile.ZIP_STORED) as new_zip:
            for root, dirs, files in os.walk(tmpdir):
                for file in files:
                    full_path = os.path.join(root, file)
                    rel_path = os.path.relpath(full_path, tmpdir)
                    new_zip.write(full_path, rel_path)
        
        print(f"Fixed model created at {fixed_path}")

if __name__ == "__main__":
    fix_nemo_config(ORIGINAL_NEMO, FIXED_NEMO)
