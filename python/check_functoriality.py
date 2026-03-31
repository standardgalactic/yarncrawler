import sys
from common.common_io import load_json, save_json

source_file, transferred_file, output_file = sys.argv[1:4]

src = load_json(source_file)
tgt = load_json(transferred_file)

score = 1.0

if src.get("domain") != tgt.get("domain") and "transferred" not in tgt.get("properties", []):
    score -= 0.5

if src.get("codomain") != tgt.get("codomain") and tgt.get("codomain") is not None:
    score -= 0.25

if "transferred_from" not in tgt:
    score -= 0.25

save_json(output_file, {
    "functoriality_score": max(0.0, score)
})
