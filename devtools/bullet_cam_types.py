#!/usr/bin/env python3
"""Which zombie types the sniper BULLET CAM must skip (effects/bullet_cam.gd -> UNSAFE).

The bullet cam starts only when zombie.gd -> lethal_hit() is sure the shot kills. That estimate copies
take_damage() but cannot see what a type does in on_damage() / damage_mult() when those depend on state
(shields that block from the front, armor that soaks hits, hit counters, bosses that ignore damage...).
So every type whose on_damage() can block a hit, writes hp, or whose damage_mult() changes anything
(sounds, effects, its own variables) is UNSAFE, plus stationary bosses and types that have both.
Children inherit from the type they extend.

usage:  python3 devtools/bullet_cam_types.py          prints the GDScript list (paste it over UNSAFE)
        python3 devtools/bullet_cam_types.py --check  exit 1 if bullet_cam.gd's list is out of date
Run it after adding or changing zombie types in shooter_game/enemies/types/.
"""
import os
import re
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "shooter_game")
TYPES = os.path.join(ROOT, "enemies", "types")
CAM = os.path.join(ROOT, "effects", "bullet_cam.gd")


def body(src, name):
    m = re.search(r"^func %s\(.*?$" % name, src, re.M)
    if not m:
        return None
    out = []
    for ln in src[m.end():].split("\n")[1:]:
        if ln and not ln[0].isspace() and not ln.startswith("#"):
            break
        out.append(ln)
    return "\n".join(out)


def classify():
    res = {}
    for f in sorted(os.listdir(TYPES)):
        if not f.endswith(".gd"):
            continue
        src = open(os.path.join(TYPES, f), encoding="utf-8").read()
        m = re.search(r'^extends "(.*?)"', src, re.M)
        ext = m.group(1) if m else ""
        od = body(src, "on_damage")
        dm = body(src, "damage_mult")
        block = False   # on_damage can return false (hit blocked / absorbed)
        if od is not None:
            for r in re.findall(r"^\s*return\s+(.*)$", od, re.M):
                r = r.split("#")[0].strip()
                if r != "true" and not r.startswith("super.on_damage"):
                    block = True
        impure = False   # damage_mult does more than compute a number
        if dm is not None:
            locs = set(re.findall(r"^\s*var\s+(\w+)", dm, re.M))
            for ln in dm.split("\n"):
                s = ln.split("#")[0]
                if re.search(r"Sfx\.|Particles\.|_popup|\.emit|call_deferred|\.call\(", s):
                    impure = True
                a = re.match(r"^\s*([\w\.\[\]]+)\s*(=|\+=|-=|\*=|/=)\s*[^=]", s)
                if a and not re.match(r"^\s*var\s", s) and a.group(1).split(".")[0].split("[")[0] not in locs:
                    impure = True
        res[f] = {"ext": ext, "od": od is not None, "block": block, "dm": dm is not None, "impure": impure,
                  "hp_write": bool(re.search(r"z\.hp\s*(=|\+=|-=)", od or "")), "stationary": "stationary_boss" in ext}
    for f, r in res.items():   # children inherit what they do not override
        if "types/" in r["ext"]:
            p = res.get(os.path.basename(r["ext"]))
            if p is not None:
                if not r["od"]:
                    r["block"] = p["block"]
                    r["hp_write"] = r["hp_write"] or p["hp_write"]
                if not r["dm"]:
                    r["dm"], r["impure"] = p["dm"], p["impure"]
    return sorted(f[:-3] for f, r in res.items()
                  if r["block"] or r["impure"] or r["stationary"] or r["hp_write"] or (r["od"] and r["dm"]))


def gd_list(names):
    lines, cur = [], "\t"
    for n in names:
        item = '"%s", ' % n
        if len(cur) + len(item) > 118:
            lines.append(cur.rstrip())
            cur = "\t"
        cur += item
    lines.append(cur.rstrip().rstrip(","))
    return "const UNSAFE := [\n" + "\n".join(lines) + "\n]"


if __name__ == "__main__":
    names = classify()
    if "--check" in sys.argv:
        src = open(CAM, encoding="utf-8").read()
        m = re.search(r"const UNSAFE := \[(.*?)\]", src, re.S)
        have = sorted(re.findall(r'"(\w+)"', m.group(1))) if m else []
        if have == names:
            print("UNSAFE list up to date (%d types)" % len(names))
            sys.exit(0)
        print("UNSAFE list out of date: add %s, remove %s" % (sorted(set(names) - set(have)), sorted(set(have) - set(names))))
        sys.exit(1)
    print(gd_list(names))
