import sys, yaml
from collections import deque

rules_file, src, tgt = sys.argv[1:4]

rules = yaml.safe_load(open(rules_file))

queue = deque([(src, [src])])
visited = set()

while queue:
    cur, path = queue.popleft()
    if cur == tgt:
        print("->".join(path))
        sys.exit(0)
    for nxt in rules.get(cur, []):
        if nxt not in visited:
            visited.add(nxt)
            queue.append((nxt, path + [nxt]))

print("NO_PATH")
sys.exit(1)
