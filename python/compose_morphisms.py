import sys
import subprocess
from common.common_io import save_json

rules = "state/typing_rules.yaml"
paths = sys.argv[1:-1]
out = sys.argv[-1]

for i in range(len(paths) - 1):
    subprocess.run([
        "python3", "python/check_composable.py",
        paths[i], paths[i + 1], rules
    ], check=True)

save_json(out, {
    "type": "composite",
    "sequence": paths,
    "properties": ["typed_composed"]
})
