import os, re, sys
root = sys.argv[1]
need = ("getSUPPORT_DESKTOP_WINDOWING", "getSUPPORT_TABLET_TYPE", "getSupportDexStandAlone")
meth_re = re.compile(r"^\.method public static (\w+)\(Landroid/content/Context;\)Z\n.*?^\.end method\n", re.S | re.M)
hits = []
for d, _, fs in os.walk(root):
    for f in fs:
        if not f.endswith(".smali"): continue
        p = os.path.join(d, f)
        s = open(p, encoding="utf-8").read()
        if "getSUPPORT_TABLET_TYPE" not in s: continue
        for m in meth_re.finditer(s):
            if all(k in m.group(0) for k in need):
                hits.append((p, m))
if len(hits) != 1:
    print(f"found {len(hits)} candidates"); sys.exit(1)
p, m = hits[0]
s = open(p, encoding="utf-8").read()
new = (f".method public static {m.group(1)}(Landroid/content/Context;)Z\n"
       "    .locals 1\n\n    const/4 v0, 0x1 # a82xq-wdex-tile\n\n    return v0\n.end method\n")
s = s[:m.start()] + new + s[m.end():]
open(p, "w", encoding="utf-8").write(s)
print("patched", p, m.group(1))
