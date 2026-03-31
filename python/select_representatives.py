import sys
from common.common_io import load_json, save_json

classes_file, controllers_dir, output = sys.argv[1:4]

data = load_json(classes_file)
classes = data["classes"]

reps = []

for cls in classes:
    best = None
    best_score = -1e9

    for cid in cls:
        c = load_json(f"{controllers_dir}/{cid}.json")
        score = c.get("stability_score", 0)

        if score > best_score:
            best_score = score
            best = cid

    reps.append(best)

save_json(output, {"representatives": reps})
