#!/usr/bin/env python3
# Add the Galaxy Quantum2 (a82xq) 16MP-family sizes to SamsungCamera's Resolution enum.
import os, re, sys
root = sys.argv[1]
RES = 'Lcom/sec/android/app/camera/interfaces/Resolution;'
AR  = 'Lcom/sec/android/app/camera/interfaces/AspectRatio;'
TAG = '# a82xq-res-patch'
NEW = [  # name, width, height, template (aspect ratio / fps / icon copied from it)
    ('RESOLUTION_4624X3468', 4624, 3468, 'RESOLUTION_4000X3000'),
    ('RESOLUTION_4624X2604', 4624, 2604, 'RESOLUTION_4032X2268'),
    ('RESOLUTION_4624X2084', 4624, 2084, 'RESOLUTION_4032X1816'),
    ('RESOLUTION_3472X3472', 3472, 3472, 'RESOLUTION_3024X3024'),
    ('RESOLUTION_4000X2250', 4000, 2250, 'RESOLUTION_4032X2268'),
    ('RESOLUTION_2576X1160', 2576, 1160, 'RESOLUTION_4032X1816'),
]
ID_BASE = 0x3e8

def rd(p): return open(p, encoding='utf-8').read()
def wr(p, s): open(p, 'w', encoding='utf-8').write(s)

resp = None
for d, _, fs in os.walk(root):
    if 'Resolution.smali' in fs and d.endswith('com/sec/android/app/camera/interfaces'):
        resp = os.path.join(d, 'Resolution.smali')
assert resp, 'Resolution.smali not found'
s = rd(resp)
if TAG in s:
    print('skip: already patched'); sys.exit(0)
for n, *_ in NEW:
    assert ('->%s:' % n) not in s and ('enum %s:' % n) not in s, n + ' already exists'

# 1) static fields
anchor = '.field public static final enum RESOLUTION_4032X3024:%s\n' % RES
assert s.count(anchor) == 1
s = s.replace(anchor, anchor + ''.join('\n%s\n.field public static final enum %s:%s\n' % (TAG, n, RES) for n, *_ in NEW), 1)

# 2) $values(): grow array and append
m = re.search(r'(\.method private static synthetic \$values\(\)\[[^\n]*\n\s*\.locals \d+\n\s*const/16 v0, )(0x[0-9a-f]+)', s)
assert m, '$values header not found'
old = int(m.group(2), 16)
s = s[:m.start(2)] + hex(old + len(NEW)) + s[m.end(2):]
vs = m.start()
ve = s.index('.end method', vs)
ri = s.rindex('return-object v0', vs, ve)
add = '    %s\n' % TAG
for i, (n, *_ ) in enumerate(NEW):
    add += '    sget-object v1, %s->%s:%s\n\n    const/16 v2, %s\n\n    aput-object v1, v0, v2\n\n' % (RES, n, RES, hex(old + i))
s = s[:ri] + add + '    ' + s[ri:].lstrip(' ')

# 3) <clinit>: construct before $values()
call = '    invoke-static {}, %s->$values()[%s\n' % (RES, RES)
assert s.count(call) == 1
code = '    %s\n' % TAG
for i, (n, w, h, t) in enumerate(NEW):
    code += ('    new-instance v0, {R}\n\n'
             '    const-string v1, "{n}"\n\n'
             '    const/16 v2, {o}\n\n'
             '    const/16 v3, {id}\n\n'
             '    const/16 v4, {w}\n\n'
             '    const/16 v5, {h}\n\n'
             '    sget-object v8, {R}->{t}:{R}\n\n'
             '    invoke-virtual {{v8}}, {R}->getAspectRatio(){A}\n\n'
             '    move-result-object v6\n\n'
             '    invoke-virtual {{v8}}, {R}->getMinFps()I\n\n'
             '    move-result v7\n\n'
             '    invoke-virtual {{v8}}, {R}->getMaxFps()I\n\n'
             '    move-result v8\n\n'
             '    invoke-direct/range {{v0 .. v8}}, {R}-><init>(Ljava/lang/String;IIII{A}II)V\n\n'
             '    sput-object v0, {R}->{n}:{R}\n\n').format(
                R=RES, A=AR, n=n, o=hex(old + i), id=hex(ID_BASE + i), w=hex(w), h=hex(h), t=t)
s = s.replace(call, code + call, 1)
wr(resp, s)
print('ok   %s: %d -> %d entries' % (resp, old, old + len(NEW)))

# 4) maps keyed by Resolution (icons / megapixel tables): mirror the template entry
put_re = r'(invoke-(?:virtual|interface) \{(v\d+), %s, (v\d+)\}, L[^;]+;->put\(Ljava/lang/Object;Ljava/lang/Object;\)Ljava/lang/Object;\n)'
for d, _, fs in os.walk(root):
    for f in fs:
        if not f.endswith('.smali'): continue
        p = os.path.join(d, f)
        t = rd(p)
        if '->put(Ljava/lang/Object;Ljava/lang/Object;)' not in t or TAG in t: continue
        changed = 0
        for n, w, h, tmpl in NEW:
            for mm in list(re.finditer(r'sget-object (v\d+), %s->%s:%s\n' % (re.escape(RES), tmpl, re.escape(RES)), t)):
                key = mm.group(1)
                seg = t[mm.end():mm.end() + 1500]
                pm = re.search(put_re % re.escape(key), seg)
                if not pm: continue
                ins_at = mm.end() + pm.end()
                line = pm.group(1)
                extra = ('\n    %s\n    sget-object %s, %s->%s:%s\n\n    %s\n    sget-object %s, %s->%s:%s\n' %
                         (TAG, key, RES, n, RES, line, key, RES, tmpl, RES))
                t = t[:ins_at] + extra + t[ins_at:]
                changed += 1
                break
        if changed:
            wr(p, t); print('ok   map %s: +%d' % (os.path.relpath(p, root), changed))

# 5) quick-setting picture-size icon maps (a: icons, b: indicator icons, filled in <clinit> by
#    reusing key registers, and read without null checks): give every new size the 4000X3000 entry
#    (or 4032X3024) right before each map is stored.
TAG2 = '# a82xq-res-qsmap'
k = 0
for d, _, fs in os.walk(root):
    for f in fs:
        if not f.endswith('.smali'): continue
        p = os.path.join(d, f)
        t = rd(p)
        if 'picture_resolution' not in t or TAG2 in t: continue
        sputs = list(re.finditer(r'\n(    sput-object (v\d+), (L[^;]+;)->(\w+):(L[^;]+;)\n)', t))
        done = 0
        for m in reversed(sputs):
            reg = m.group(2)
            prev = max(t.rfind('sput-object', 0, m.start()), t.rfind('.method', 0, m.start()))
            block = t[prev:m.start()]
            if 'picture_resolution' not in block or 'AbstractMap;->put' not in block: continue
            if reg in ('v1', 'v2') or int(reg[1:]) > 15: continue
            code = '\n    %s\n' % TAG2
            for i, (n, *_ ) in enumerate(NEW):
                ok, skip = ':a82xq_qs_%d_%d_ok' % (k, i), ':a82xq_qs_%d_%d_skip' % (k, i)
                code += ('    sget-object v1, {R}->RESOLUTION_4000X3000:{R}\n\n'
                         '    invoke-virtual {{{M}, v1}}, Ljava/util/HashMap;->get(Ljava/lang/Object;)Ljava/lang/Object;\n\n'
                         '    move-result-object v1\n\n'
                         '    if-nez v1, {ok}\n\n'
                         '    sget-object v1, {R}->RESOLUTION_4032X3024:{R}\n\n'
                         '    invoke-virtual {{{M}, v1}}, Ljava/util/HashMap;->get(Ljava/lang/Object;)Ljava/lang/Object;\n\n'
                         '    move-result-object v1\n\n'
                         '    {ok}\n'
                         '    if-eqz v1, {skip}\n\n'
                         '    sget-object v2, {R}->{n}:{R}\n\n'
                         '    invoke-virtual {{{M}, v2, v1}}, Ljava/util/HashMap;->putIfAbsent(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;\n\n'
                         '    {skip}\n').format(R=RES, M=reg, n=n, ok=ok, skip=skip)
            t = t[:m.start() + 1] + code + '\n' + t[m.start() + 1:]
            done += 1
            k += 1
        if done:
            wr(p, t); print('ok   qsmap %s: %d map(s)' % (os.path.relpath(p, root), done))

# 6) ZoomShortcutListView item decoration divides by (item count - 1); with a single zoom
#    shortcut (64MP mode on a82xq) that is 0 -> ArithmeticException. Guard every int divisor.
TAG3 = '# a82xq-div0-guard'
for d, _, fs in os.walk(root):
    for f in fs:
        if f != 'ZoomShortcutListView$ContentsItemDecoration.smali': continue
        p = os.path.join(d, f)
        t = rd(p)
        if TAG3 in t: continue
        cnt = [0]
        def guard(m):
            ind, op, regs = m.group(1), m.group(2), m.group(3)
            div = regs.split(',')[-1].strip()
            lbl = ':a82xq_div_ok_%d' % cnt[0]; cnt[0] += 1
            return ('%s%s\n%sif-nez %s, %s\n\n%sconst/16 %s, 0x1\n\n%s%s\n%s%s %s\n'
                    % (ind, TAG3, ind, div, lbl, ind, div, ind, lbl, ind, op, regs))
        t = re.sub(r'^( +)((?:div|rem)-int(?:/2addr)?) (v\d+, v\d+(?:, v\d+)?)\n', guard, t, flags=re.M)
        wr(p, t); print('ok   div0 guard %s: %d' % (os.path.relpath(p, root), cnt[0]))
