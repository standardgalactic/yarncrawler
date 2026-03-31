import sys
from common.common_io import load_json, save_json

c1_file, c2_file, classes_file, output = sys.argv[1:5]

c1 = load_json(c1_file)
c2 = load_json(c2_file)
classes = load_json(classes_file)["classes"]

def find_class(cid):
    for cls in classes:
        if cid in cls["members"]:
            return cls["class_id"]
    return None

cl1 = find_class(c1["id"])
cl2 = find_class(c2["id"])

save_json(output, {
    "from_class": cl1,
    "to_class": cl2,
    "same_class": cl1 == cl2
})
