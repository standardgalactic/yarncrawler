import sys
from common.common_io import save_json

src, tgt, output = sys.argv[1:4]

save_json(output, {
  "type": "symbolic",
  "domain": src,
  "codomain": tgt,
  "properties": ["bridge"]
})
