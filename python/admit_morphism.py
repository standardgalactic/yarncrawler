import sys
import uuid
import os
from common.common_io import load_json, save_json

morphism_file, score_file, registry_dir = sys.argv[1:4]

m = load_json(morphism_file)
score = load_json(score_file).get("score", -1e9)

THRESHOLD = -0.5  # tune this

# Reject low-quality morphisms
if score < THRESHOLD:
    sys.exit(0)

# Ensure registry structure exists
entries_dir = os.path.join(registry_dir, "entries")
os.makedirs(entries_dir, exist_ok=True)

index_file = os.path.join(registry_dir, "index.json")

# Load or initialize index
if os.path.exists(index_file):
    index = load_json(index_file)
else:
    index = {"morphisms": []}

# Generate unique ID
mid = "morph_" + uuid.uuid4().hex[:8]

entry = {
    "id": mid,
    "operator": m,
    "properties": m.get("properties", []),
    "created_from": morphism_file,
    "contexts": [],
    "usage_count": 0,
    "success_count": 0,
    "score_mean": score,
    "score_var": 0.0
}

# Write entry
entry_path = os.path.join(entries_dir, f"{mid}.json")
save_json(entry_path, entry)

# Update index
index["morphisms"].append(mid)
save_json(index_file, index)
