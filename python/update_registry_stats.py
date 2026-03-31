import sys
from common.common_io import load_json, save_json

entry_file, score_file = sys.argv[1:3]

entry = load_json(entry_file)
score = load_json(score_file).get("score", 0.0)

n = entry.get("usage_count", 0)
mean = entry.get("score_mean", 0.0)
m2 = entry.get("score_var", 0.0)

new_n = n + 1
delta = score - mean
new_mean = mean + delta / new_n
delta2 = score - new_mean
new_m2 = m2 + delta * delta2

entry["usage_count"] = new_n
entry["score_mean"] = new_mean
entry["score_var"] = (new_m2 / new_n) if new_n > 0 else 0.0

if score > 0:
    entry["success_count"] = entry.get("success_count", 0) + 1

save_json(entry_file, entry)
