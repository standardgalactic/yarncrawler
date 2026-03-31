import sys
from common.common_io import load_json, save_json

ctrl_file, transform_file, output_file = sys.argv[1:4]

ctrl = load_json(ctrl_file)
tr = load_json(transform_file)

new_ctrl = dict(ctrl)

new_ctrl["id"] = tr["target"]
new_ctrl["history"] = ctrl.get("history", []) + [ctrl["id"]]
new_ctrl["transformed_from"] = ctrl["id"]

save_json(output_file, new_ctrl)
