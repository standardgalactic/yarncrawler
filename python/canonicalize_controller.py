import sys
from common.common_io import load_json, save_json

ctrl_file, classes_file, output = sys.argv[1:4]

ctrl = load_json(ctrl_file)
classes = load_json(classes_file)["classes"]

for cls in classes:
    if ctrl["id"] in cls["members"]:
        save_json(output, {
            "id": cls["representative"],
            "canonical": True
        })
        sys.exit(0)

save_json(output, ctrl)
