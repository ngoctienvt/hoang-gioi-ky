"""Ghi/cap nhat muc assets trong assets/asset-manifest.json tu items.json + art-source/previews/models/stats.json.
python manifest_update.py [batch]  (mac dinh 2)"""
import json, sys
from pathlib import Path
HERE = Path(__file__).resolve().parent; G = HERE.parents[1]
batch = int(sys.argv[1]) if len(sys.argv) > 1 else 2
items = json.loads((HERE / "items.json").read_text(encoding="utf-8"))
picks = json.loads((HERE / "picks.json").read_text(encoding="utf-8"))
st = json.loads((G / "art-source/previews/models/stats.json").read_text())
mp = G / "assets/asset-manifest.json"; man = json.loads(mp.read_text(encoding="utf-8"))
by = {a["id"]: a for a in man["assets"]}
RIG = {"quadruped": "creature_rig.py (Tong Mon) — xuong 4 chan + clip thu tuc", "serpent": "creature_rig.py --kind serpent",
       "bird": "bird_rig.py (Tong Mon) — xuong chim + clip bay", "hop": "rigid_rig.py --style hop", "float": "rigid_rig.py --style float"}
n = 0
for it in items:
    if it.get("batch", 1) != batch: continue
    f = it["file"]; s = st.get(f)
    if not s: print("NO_STATS", f); continue
    x, y, z = s["dims_xyz"]  # Blender: x rong, y sau, z cao -> manifest [X, Z(sau), Y(cao)] nhu Dot 1
    e = by.get(f, {})
    e.update({"id": f, "file": f"assets/models/{it['folder']}/{it['key']}/{f}.glb", "category": it["folder"], "priority": "P1", "batch": batch,
              "game_id": it.get("game_id"), "style_anchor": False, "dimensions_m": [x, y, z], "triangles": s["tris"], "texture": "embedded",
              "animations": s["anims"],
              "source": {"kind": "ai_generated", "concept_tool": "Qwen-Image 2512 + BiRefNet (ComfyUI, local)", "concept_seed": picks.get(it["key"], 11),
                         "concept_prompt": it["prompt"], "mesh_tool": "Hunyuan3D-Omni (bbox control)",
                         "texture_tool": "Hunyuan3D-2.1 Paint, kéo màu về bảng màu phase-01, nâng sáng x1.17", "rig_tool": RIG.get(it.get("rig")),
                         "controls": ["bbox"], "human_edits": "giữ nguyên mesh Omni (không giảm tam giác); chỉ scale, pivot, hướng mặt, màu; metallicFactor=0"},
              "license": "Tencent Hunyuan 3D Community License — chưa chốt (giới hạn EU/UK/KR, >1M MAU)",
              "technical_checks_passed": True, "approved_by": None, "approved_date": None})
    if f not in by: man["assets"].append(e); by[f] = e
    n += 1
mp.write_text(json.dumps(man, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
print("MANIFEST", n, "total", len(man["assets"]))
