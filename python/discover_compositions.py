import sys
import json
from collections import Counter
from common.common_io import save_json

history_file, output_file = sys.argv[1:3]

pairs = Counter()

with open(history_file, "r") as f:
    prev = None
    for line in f:
        row = json.loads(line)
        morph = row.get("morphism")
        score = row.get("score", -1e9)

        if prev and score > 0:
            pairs[(prev, morph)] += 1
        prev = morph

top = pairs.most_common(10)

results = []
for (a, b), _ in top:
    results.append({
        "type": "composite",
        "sequence": [a, b],
        "properties": ["composed"]
    })

save_json(output_file, results)
