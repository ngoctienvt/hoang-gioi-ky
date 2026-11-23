"""Buoc 2: anh da chon -> D:/hgk_models/rgba/<key>.png + omni_jobs.json + m/names.json. Chon seed trong picks.json {key: seed} (mac dinh 11).
python prep.py [key ...]   (khong truyen key = tat ca)"""
import json, shutil, sys
from pathlib import Path
HERE = Path(__file__).resolve().parent; OUT = Path(r"D:\hgk_models")
items = json.loads((HERE / "items.json").read_text(encoding="utf-8"))
picks = json.loads((HERE / "picks.json").read_text(encoding="utf-8")) if (HERE / "picks.json").exists() else {}
only = set(sys.argv[1:])
(OUT / "rgba").mkdir(parents=True, exist_ok=True); (OUT / "m").mkdir(parents=True, exist_ok=True)
jobs, names = [], []
for it in items:
    k = it["key"]
    if only and k not in only: continue
    src = OUT / "img" / k / f"s{picks.get(k, 11)}.png"
    if not src.exists(): print("NO_IMG", k); continue
    shutil.copy(src, OUT / "rgba" / f"{k}.png")
    d = it["dims"]; mx = max(d)
    jobs.append({"image": f"/mnt/d/hgk_models/rgba/{k}.png", "bbox": [round(max(x / mx, 0.05), 3) for x in d], "out": f"/mnt/d/hgk_models/m/{k}/omni.glb", "seed": 1234})
    names.append(k)
(HERE / "omni_jobs.json").write_text(json.dumps(jobs, indent=1), encoding="utf-8")
(OUT / "m" / "names.json").write_text(json.dumps(names), encoding="utf-8")
print("PREP", len(jobs))
