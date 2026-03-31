import json
from pathlib import Path

def load_json(path):
    return json.loads(Path(path).read_text())

def save_json(path, obj):
    Path(path).write_text(json.dumps(obj, indent=2))

def append_jsonl(path, obj):
    with open(path, "a") as f:
        f.write(json.dumps(obj) + "\n")
