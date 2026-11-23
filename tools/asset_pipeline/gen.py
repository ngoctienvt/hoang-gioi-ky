"""Hoang Gioi Ky, buoc 1: anh concept (Qwen-Image 2512 qua ComfyUI) + mask BiRefNet -> D:/hgk_models/img/<key>/s<seed>.png (RGBA).
python gen.py [seed ...]   (mac dinh 11 23; bo qua anh da co). Sau do: bang xem art-source/previews/concepts_<folder>.jpg.
Theo flow reports/exp3d/{dem,thd} cua Tong Mon; prompt theo plans/261123-1413-3d-asset-pipeline-hunyuan3d-omni/phase-01."""
import json, sys, traceback
from pathlib import Path
ROOT = Path(r"C:\Users\Admin\workspace\animation2d"); sys.path.insert(0, str(ROOT))
from anim2d.comfy import ComfyClient
from anim2d.workflows import image_graph, node
from PIL import Image, ImageDraw
HERE = Path(__file__).resolve().parent; GAME = HERE.parents[1]; OUT = Path(r"D:\hgk_models")
LOOK = ("gloomy mysterious fantasy wilderness, survival game mood, hand-painted flat colors with soft gradients, "
        "muted earthy desaturated palette, olive green, umber brown, rust, ash grey, weathered and worn, chunky simple shapes, soft rounded forms")
VIEW = {
 "prop": "single object centered, full object visible with margin, three-quarter front view from slightly above",
 "quad": "slightly stylized natural proportions, not chibi, full body standing on all four legs, three-quarter front view at eye level, the head and face clearly visible, all legs and the tail visible",
 "bird": "slightly stylized natural proportions, not chibi, full body hovering in the air with the wings spread wide open to both sides, straight front view at eye level, the head and face clearly visible, the tail and legs visible",
 "serpent": "slightly stylized, not chibi, the long body coiled in a compact pile with the head raised up facing the viewer, three-quarter front view at eye level, the head clearly visible",
 "monster": "slightly stylized, not chibi, full body standing upright, straight front view at eye level, orthographic, arms slightly away from the body, the face clearly visible",
 "human": "slightly stylized natural proportions, not chibi, full body, straight front view at eye level, orthographic, standing upright facing the viewer in a relaxed A-pose, arms slightly away from the body, empty hands, the face clearly visible"}
TAIL = "plain light grey background, flat even lighting, no shadow, no ground, no text, no outline"
NEG = ("bright saturated colors, cheerful, cute pastel, neon, chibi, big head, photorealistic, PBR, shiny metal, high detail noise, glow, aura, magic effects, "
       "particles, smoke, fire, flames, text, logo, watermark, multiple objects, ground, scene, harsh shadow, black outline, cropped, blurry")
NEG_K = {"prop": "", "quad": ", realistic animal, realistic fur, fur strands, wildlife photo, humanoid, standing on two legs, rider, saddle, top view, back view",
         "bird": ", realistic bird photo, perched, sitting, folded wings, top view, back view, side view, multiple creatures",
         "serpent": ", legs, humanoid, top view, back view, multiple creatures",
         "monster": ", weapon, three-quarter view, side view, perspective distortion, multiple characters",
         "human": ", weapon, tool, three-quarter view, side view, perspective distortion, multiple characters"}

def prompt(it):
    head = "stylized low-poly 3D game character" if it["kind"] == "human" else ("stylized low-poly 3D game creature" if it["kind"] in ("quad", "bird", "serpent", "monster") else "stylized low-poly 3D game asset")
    return f"{head}, {it['prompt']}, {it.get('look', LOOK)}, {VIEW[it['kind']]}, {TAIL}"

if __name__ == "__main__":
    av = sys.argv[1:]; keys = None
    if "--keys" in av: i = av.index("--keys"); keys = set(av[i + 1].split(",")); av = av[:i] + av[i + 2:]
    seeds = [int(s) for s in av] or [11, 23]
    items = json.loads((HERE / "items.json").read_text(encoding="utf-8"))
    if keys: items = [it for it in items if it["key"] in keys]
    api = ComfyClient("http://127.0.0.1:8188")
    for it in items:
        k = it["key"]
        for sd in seeds:
            dst = OUT / "img" / k / f"s{sd}.png"
            if dst.exists(): continue
            try:
                d = OUT / "raw" / f"{k}_{sd}"
                spec = {"id": f"hgk_{k}_{sd}", "image": {"prompt": prompt(it), "negative": NEG + NEG_K[it["kind"]], "width": 1024, "height": 1024, "steps": 30}}
                g = image_graph("qwen", spec, sd)
                g["20"] = node("LoadBackgroundRemovalModel", bg_removal_name="birefnet.safetensors")
                g["21"] = node("RemoveBackground", bg_removal_model=["20", 0], image=["9", 0])
                g["22"] = node("MaskToImage", mask=["21", 0])
                g["23"] = node("SaveImage", images=["22", 0], filename_prefix=f"animation2d/hgk_{k}_{sd}/mask")
                st = api.execute(g, d)
                fs = [d / Path(x["local"]).name for x in st["outputs"] if x["kind"] == "images"]
                rgb = next(f for f in fs if "qwen_" in f.name and "mask" not in f.name); m = next(f for f in fs if "mask" in f.name)
                o = Image.open(rgb).convert("RGB"); o.putalpha(Image.open(m).convert("L")); dst.parent.mkdir(parents=True, exist_ok=True); o.save(dst)
                print("IMG", k, sd, flush=True)
            except Exception:
                traceback.print_exc(); print("IMG_FAIL", k, sd, flush=True)
    # bang xem theo thu muc
    pv = GAME / "art-source" / "previews"; pv.mkdir(parents=True, exist_ok=True); C = 300
    for folder in (["redo"] if keys else sorted({it["folder"] for it in items})):
        its = items if keys else [it for it in items if it["folder"] == folder]; cols = 4; W = C * len(seeds)
        sheet = Image.new("RGB", (W * cols, (C + 22) * ((len(its) + cols - 1) // cols)), (30, 30, 30)); dr = ImageDraw.Draw(sheet)
        for i, it in enumerate(its):
            x0, y0 = (i % cols) * W, (i // cols) * (C + 22)
            dr.text((x0 + 6, y0 + 4), f"{it['key']}  ({' | '.join('s%d' % s for s in seeds)})", fill=(240, 210, 120))
            for j, sd in enumerate(seeds):
                p = OUT / "img" / it["key"] / f"s{sd}.png"
                if p.exists():
                    im = Image.open(p).convert("RGBA"); bg = Image.new("RGBA", im.size, (200, 200, 194, 255)); bg.alpha_composite(im)
                    sheet.paste(bg.convert("RGB").resize((C - 4, C - 4)), (x0 + j * C + 2, y0 + 22))
        sheet.save(pv / f"concepts_{folder}.jpg", quality=86)
    print("GEN_DONE", flush=True)
