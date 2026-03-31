import sys, os
from common.common_io import load_json, save_json

classes_file, out_dir = sys.argv[1:3]

os.makedirs(out_dir, exist_ok=True)

data = load_json(classes_file)

for cls in data["classes"]:
    cid = cls["class_id"]
    save_json(f"{out_dir}/{cid}.json", cls)
