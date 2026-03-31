import sys
from common.common_io import load_json, save_json

ctrl_file, transform_file, output_file = sys.argv[1:4]

ctrl = load_json(ctrl_file)
tr = load_json(transform_file)

out = dict(ctrl)
out["id"] = tr["target"]
out["transformed_from"] = ctrl["id"]
out["properties"] = sorted(set(out.get("properties", []) + ["transformed"]))

save_json(output_file, out)
