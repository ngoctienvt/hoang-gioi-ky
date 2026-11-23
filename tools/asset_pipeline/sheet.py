"""Ghep anh xem truoc art-source/previews/models/*.png thanh bang theo thu muc, kem kich thuoc, so tam giac."""
import json
from pathlib import Path
from PIL import Image, ImageDraw
HERE = Path(__file__).resolve().parent; GAME = HERE.parents[1]; P = GAME / "art-source" / "previews"
items = json.loads((HERE / "items.json").read_text(encoding="utf-8")); st = json.loads((P / "models" / "stats.json").read_text())
C = 300
for folder in sorted({it["folder"] for it in items}):
    names = [n for n in sorted(st) if any(it["folder"] == folder and (n == it["file"] or n in (it.get("variants") or {})) for it in items if "file" in it)]
    if not names: continue
    cols = 6; sh = Image.new("RGB", (C * cols, (C + 34) * ((len(names) + cols - 1) // cols)), (28, 28, 28)); dr = ImageDraw.Draw(sh)
    for i, n in enumerate(names):
        x, y = (i % cols) * C, (i // cols) * (C + 34); s = st[n]
        dr.text((x + 4, y + 2), n, fill=(240, 210, 120)); dr.text((x + 4, y + 17), f"{s['dims_xyz']} m  {s['tris']} tris {'anim %d' % len(s['anims']) if s['anims'] else ''}", fill=(200, 200, 200))
        p = P / "models" / f"{n}.png"
        if p.exists(): sh.paste(Image.open(p).convert("RGB").resize((C - 4, C - 4)), (x + 2, y + 32))
    sh.save(P / f"models_{folder}.jpg", quality=86); print("SHEET", folder, len(names))
