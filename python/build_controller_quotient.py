import sys, os
from common.common_io import load_json, save_json

controllers_dir, output = sys.argv[1:3]

files = [f for f in os.listdir(controllers_dir) if f.endswith(".json")]

EPS = 0.5

def dist(a, b):
    d = 0.0
    if a["id"] != b["id"]:
        d += 0.5
    for k in set(a.get("parameters", {})) | set(b.get("parameters", {})):
        d += abs(a["parameters"].get(k, 0) - b["parameters"].get(k, 0))
    return d

classes = []

for f in files:
    c = load_json(os.path.join(controllers_dir, f))
    placed = False

    for cls in classes:
        if dist(c, cls[0]) < EPS:
            cls.append(c)
            placed = True
            break

    if not placed:
        classes.append([c])

out = []
for i, cls in enumerate(classes):
    ids = [c["id"] for c in cls]

    # representative = highest stability
    best = max(cls, key=lambda x: x.get("stability_score", 0))

    out.append({
        "class_id": f"class_{i:04d}",
        "members": ids,
        "representative": best["id"],
        "stability_mean": sum(c.get("stability_score", 0) for c in cls) / len(cls)
    })

save_json(output, {"classes": out})
