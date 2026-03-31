import sys
import os
from common.common_io import load_json, save_json

context_file, registry_dir, output_file = sys.argv[1:4]

ctx = load_json(context_file)

def dist(c1, c2):
    total = 0.0
    shared = False
    for k in c1:
        if k in c2 and isinstance(c1[k], (int, float)) and isinstance(c2[k], (int, float)):
            total += (c1[k] - c2[k]) ** 2
            shared = True
    return total if shared else 0.0

results = []

entries_dir = os.path.join(registry_dir, "entries")
if os.path.isdir(entries_dir):
    for fname in os.listdir(entries_dir):
        if not fname.endswith(".json"):
            continue
        entry = load_json(os.path.join(entries_dir, fname))

        contexts = entry.get("contexts", [])
        if not contexts:
            results.append((entry.get("score_mean", -1e9), entry.get("operator")))
            continue

        best = None
        for c in contexts:
            d = dist(ctx, c)
            score = entry.get("score_mean", -1e9) - d
            if best is None or score > best:
                best = score

        results.append((best if best is not None else -1e9, entry.get("operator")))

results.sort(reverse=True, key=lambda x: x[0])

top = [r[1] for r in results[:5] if r[1] is not None]

save_json(output_file, {"candidates": top})
