import sys
from common.common_io import load_json, save_json

ctrl_file, fp_file = sys.argv[1:3]

ctrl = load_json(ctrl_file)
fp = load_json(fp_file)

score = ctrl.get("stability_score", 0.0)

if fp["fixed_point"]:
    score += 1.0
else:
    score *= 0.9

ctrl["stability_score"] = score

save_json(ctrl_file, ctrl)
