import sys
from common.common_io import load_json, save_json

composite_file, output_file = sys.argv[1:3]

m = load_json(composite_file)
seq = m.get("sequence", [])

save_json(output_file, {
    "type": "abstracted",
    "source_sequence": seq,
    "properties": ["abstracted"]
})
