import sys
import yaml
from common.common_io import load_json

m1_file, m2_file, rules_file = sys.argv[1:4]

m1 = load_json(m1_file)
m2 = load_json(m2_file)

with open(rules_file, "r") as f:
    rules = yaml.safe_load(f)

cod1 = m1.get("codomain")
dom2 = m2.get("domain")

allowed = rules.get(cod1, [])

if dom2 in allowed:
    print("OK")
    sys.exit(0)
else:
    print("INVALID")
    sys.exit(1)
