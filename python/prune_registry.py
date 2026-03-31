import sys
import os
from common.common_io import load_json, save_json

registry_dir = sys.argv[1]

entries_dir = os.path.join(registry_dir, "entries")
index_file = os.path.join(registry_dir, "index.json")

if not os.path.exists(index_file):
    save_json(index_file, {"morphisms": []})
    sys.exit(0)

index = load_json(index_file)
kept = []

for mid in index.get("morphisms", []):
    path = os.path.join(entries_dir, f"{mid}.json")
    if not os.path.exists(path):
        continue

    entry = load_json(path)
    usage = entry.get("usage_count", 0)
    score_mean = entry.get("score_mean", -1e9)

    if usage > 10 and score_mean < -1.0:
        os.remove(path)
    else:
        kept.append(mid)

index["morphisms"] = kept
save_json(index_file, index)
