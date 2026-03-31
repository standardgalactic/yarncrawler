import sys
from common.common_io import load_json, save_json

context_file, classes_file, output = sys.argv[1:4]

ctx = load_json(context_file)
classes = load_json(classes_file)["classes"]

best = None
best_score = -1e9

for cls in classes:
    score = cls.get("stability_mean", 0)

    # simple context weighting
    if ctx.get("mean_entropy", 0) > 0.7:
        score += 1.0

    if score > best_score:
        best_score = score
        best = cls

save_json(output, {
    "class_id": best["class_id"],
    "representative": best["representative"]
})
