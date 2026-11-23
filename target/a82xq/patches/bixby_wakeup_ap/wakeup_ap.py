import sys, os, re
root = sys.argv[1]
def find(lit):
    for d, _, fs in os.walk(root):
        for f in fs:
            if f.endswith(".smali"):
                p = os.path.join(d, f)
                if lit in open(p, encoding="utf-8").read(): return p
    sys.exit("not found: " + lit)
def span(L, lit):
    i = next(i for i, l in enumerate(L) if lit in l)
    s = max(j for j in range(i) if L[j].startswith(".method"))
    e = next(j for j in range(i, len(L)) if L[j].startswith(".end method"))
    return s, e
p = find('"isDspModuleEnabled() : "'); L = open(p, encoding="utf-8").read().split("\n")
if not any("a82xq-wakeup-ap" in l for l in L):
    s, e = span(L, '"isDspModuleEnabled() : "')
    r = max(j for j in range(s, e) if re.match(r"^\s+return v\d+$", L[j]))
    L.insert(r, f"    const/4 {L[r].split()[-1]}, 0x0 # a82xq-wakeup-ap")
    open(p, "w", encoding="utf-8").write("\n".join(L)); print("patched", p)
p = find('"setDSPSupport() : "'); L = open(p, encoding="utf-8").read().split("\n")
if not any("a82xq-wakeup-ap" in l for l in L):
    s, e = span(L, '"setDSPSupport() : "')
    loc = next(j for j in range(s, e) if L[j].strip().startswith(".locals"))
    L.insert(loc + 1, "    const/4 p1, 0x0 # a82xq-wakeup-ap")
    open(p, "w", encoding="utf-8").write("\n".join(L)); print("patched", p)
