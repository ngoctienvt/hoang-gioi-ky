"""Buoc 4 (Blender): dua model ve quy uoc Hoang Gioi Ky va xuat GLB.
blender -b -P hgk_fit.py -- SRC DST DIMS(x,y,z m) TRIS TEX [VARIANTS_JSON]
- Model tinh: gop mesh, giam ve TRIS tam giac, scale theo canh lon nhat cua DIMS, pivot tam day, mat truoc -Y (Blender).
- Model co xuong (tu creature_rig.py): giu xuong + hoat anh, chi scale theo chieu cao DIMS[1] va dat pivot.
- Texture: chi giu Base Color, thu ve TEX px, keo mau ve bang mau chuan (phase-01), metallic 0, roughness 1.
- Env HGK_KEEP=1: giu nguyen mesh va do phan giai texture goc (chi scale, pivot, huong, mau). Mac dinh tu 23-11.
- Env HGK_LOW=<low.glb tu simplify.py>: model tinh dung mesh thap do, UV moi, bake mau tu mesh goc (giu hinh tot hon decimate).
- VARIANTS_JSON {"ten_file": hue_do | null}: xuat them ban doi mau (vd dan duoc dung chung mesh)."""
import bpy, sys, json, colorsys, os, struct
import numpy as np
from mathutils import Vector, Matrix
a = sys.argv[sys.argv.index("--") + 1:]
src, dst = a[0], a[1]; dims = [float(x) for x in a[2].split(",")]; TRIS = int(a[3]); TEX = int(a[4])
VAR = (json.load(open(a[5], encoding="utf-8")) if a[5].endswith(".json") else json.loads(a[5])) if len(a) > 5 else {}  # file .json: PowerShell lam mat dau ngoac kep khi truyen chuoi JSON
PAL = ["808C47","4E5B32","2E3624","5F6340","6B5A3E","7E9C6E","94472E","B37636","5C4A63","A07A52","5C4332","33261E","8F8C80","6B6A62",
       "3E3D3A","B89E62","6E4E38","6A6763","CFC6B4","9A774A","852D26","A88B4E","C9A386","5FD3E0","9FE8C8","D9532E","F29A3A","E8C24A"]
P = np.array([[int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)] for h in PAL], dtype=np.float32)

bpy.ops.wm.read_factory_settings(use_empty=True); bpy.ops.import_scene.gltf(filepath=src)
arm = [o for o in bpy.data.objects if o.type == "ARMATURE"]
ms = [o for o in bpy.data.objects if o.type == "MESH"]
if arm:  # bo mesh hinh xuong (Icosphere...) khong skin vao armature, neu khong se lech bbox/ti le
    for o in [o for o in ms if not any(md.type == "ARMATURE" for md in o.modifiers)]:
        print("DROP_MESH", o.name); bpy.data.objects.remove(o, do_unlink=True)
    ms = [o for o in bpy.data.objects if o.type == "MESH"]
BRIGHT = float(os.environ.get("HGK_BRIGHT", "1.17"))  # plan Dot 2: texture Dot 1 toi (~0.24 sRGB), nang sang 15-20%
KEEP = os.environ.get("HGK_KEEP") == "1"  # giu nguyen mesh + texture goc cua Omni/Paint, khong giam
LOW = None if KEEP else os.environ.get("HGK_LOW")
if LOW and not arm and os.path.exists(LOW):
    # mesh thap (simplify.py) -> UV moi -> bake mau tu mesh Paint goc (high) sang
    hi = ms; before = set(bpy.data.objects); bpy.ops.import_scene.gltf(filepath=LOW)
    lo = [o for o in bpy.data.objects if o not in before and o.type == "MESH"][0]
    for o in [o for o in bpy.data.objects if o not in before]:
        if o is not lo and o.type != "MESH": pass
    lo.data.materials.clear()
    hp = [o.matrix_world @ v.co for o in hi for v in o.data.vertices]
    size = max((max(p[i] for p in hp) - min(p[i] for p in hp)) for i in range(3))
    bpy.ops.object.select_all(action="DESELECT"); lo.select_set(True); bpy.context.view_layer.objects.active = lo
    bpy.ops.object.mode_set(mode="EDIT"); bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=1.15, island_margin=0.015); bpy.ops.object.mode_set(mode="OBJECT")
    img = bpy.data.images.new("baked", TEX, TEX); mat = bpy.data.materials.new("baked"); mat.use_nodes = True
    tn = mat.node_tree.nodes.new("ShaderNodeTexImage"); tn.image = img
    mat.node_tree.links.new(tn.outputs["Color"], mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"])
    mat.node_tree.nodes.active = tn; lo.data.materials.append(mat)
    sc = bpy.context.scene; sc.render.engine = "CYCLES"; sc.cycles.samples = 1
    sc.cycles.device = "CPU"
    for o in hi: o.hide_render = False; o.select_set(True)
    lo.select_set(True); bpy.context.view_layer.objects.active = lo
    bpy.ops.object.bake(type="DIFFUSE", pass_filter={"COLOR"}, use_selected_to_active=True,
                        cage_extrusion=size * 0.02, max_ray_distance=size * 0.08, margin=6)
    img.pack()
    hm = {m for o in hi for m in o.data.materials if m}
    for o in hi: bpy.data.objects.remove(o, do_unlink=True)
    for m in hm:
        for nd in m.node_tree.nodes if m.use_nodes else []:
            if nd.type == "TEX_IMAGE" and nd.image: bpy.data.images.remove(nd.image)
        bpy.data.materials.remove(m)
    ms = [lo]; print("BAKED", LOW, len(lo.data.polygons))
def world_pts():
    dg = bpy.context.evaluated_depsgraph_get(); pts = []
    for o in ms:
        e = o.evaluated_get(dg); pts += [e.matrix_world @ v.co for v in e.data.vertices]
    return pts
if not arm:
    bpy.ops.object.select_all(action="DESELECT")
    for o in ms: o.select_set(True)
    bpy.context.view_layer.objects.active = ms[0]
    if len(ms) > 1: bpy.ops.object.join()
    o = bpy.context.view_layer.objects.active; o.parent = None; ms = [o]
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    for x in list(bpy.data.objects):
        if x is not o: bpy.data.objects.remove(x, do_unlink=True)
    if not KEEP:
        bpy.ops.object.mode_set(mode="EDIT"); bpy.ops.mesh.select_all(action="SELECT"); bpy.ops.mesh.remove_doubles(threshold=1e-5)
        bpy.ops.mesh.quads_convert_to_tris(); bpy.ops.object.mode_set(mode="OBJECT")
    n = len(o.data.polygons)
    if n > TRIS and not KEEP:
        md = o.modifiers.new("dec", "DECIMATE"); md.ratio = TRIS * 0.98 / n; bpy.ops.object.modifier_apply(modifier="dec")
    vs = [v.co for v in o.data.vertices]
    lo = Vector([min(v[i] for v in vs) for i in range(3)]); hi = Vector([max(v[i] for v in vs) for i in range(3)])
    sz = hi - lo; c = (hi + lo) / 2; s = max(dims) / max(sz)
    o.data.transform(Matrix.Translation(-Vector((c.x, c.y, lo.z)))); o.data.transform(Matrix.Diagonal((s, s, s, 1.0)))
    try: bpy.ops.object.shade_smooth_by_angle(angle=0.61)
    except Exception as e: print("smooth skip", e)
else:
    pts = world_pts(); lo = Vector([min(p[i] for p in pts) for i in range(3)]); hi = Vector([max(p[i] for p in pts) for i in range(3)])
    s = dims[1] / (hi.z - lo.z); c = (hi + lo) / 2
    z0 = 0.0 if os.environ.get("HGK_NOFLOOR") == "1" else lo.z  # chim bay: giu do cao lo lung so voi goc
    for r in [x for x in bpy.data.objects if x.parent is None]:
        r.location = (r.location - Vector((c.x, c.y, z0))) * s; r.scale = r.scale * s
# texture
imgs = []
for m in bpy.data.materials:
    if not (m and m.use_nodes): continue
    for nd in list(m.node_tree.nodes):
        if nd.type == "TEX_IMAGE" and nd.image and not any(l.to_socket.name == "Base Color" for l in nd.outputs["Color"].links):
            m.node_tree.nodes.remove(nd)
    for nd in m.node_tree.nodes:
        if nd.type == "BSDF_PRINCIPLED": nd.inputs["Metallic"].default_value = 0.0; nd.inputs["Roughness"].default_value = 1.0
        if nd.type == "TEX_IMAGE" and nd.image: imgs.append(nd.image)
def pull(px):
    rgb = px[:, :3]; lum = (rgb * [0.299, 0.587, 0.114]).sum(1, keepdims=True)
    rgb = rgb + (lum - rgb) * 0.2
    d = ((rgb[:, None, :] - P[None]) ** 2).sum(2); near = P[d.argmin(1)]
    px[:, :3] = np.clip((rgb + (near - rgb) * 0.35) * BRIGHT, 0, 1); return px
base = {}
for im in imgs:
    if max(im.size) > TEX and not KEEP: im.scale(TEX, TEX)
    px = np.empty(im.size[0] * im.size[1] * 4, dtype=np.float32); im.pixels.foreach_get(px); px = pull(px.reshape(-1, 4))
    im.pixels.foreach_set(px.ravel()); im.update(); base[im.name] = px.copy()
name = dst.replace("\\", "/").split("/")[-1][:-4]
if not arm: ms[0].name = name
def patch_glb(path):
    """Ghi ro metallicFactor 0 / roughnessFactor 1, bo KHR_materials_specular & ior (Dot 1: 60/63 GLB thieu metallicFactor -> mac dinh 1.0, den si)."""
    b = open(path, "rb").read(); n = struct.unpack("<I", b[12:16])[0]; j = json.loads(b[20:20 + n]); rest = b[20 + n:]
    for m in j.get("materials", []):
        pr = m.setdefault("pbrMetallicRoughness", {}); pr["metallicFactor"] = 0.0; pr["roughnessFactor"] = 1.0
        pr.pop("metallicRoughnessTexture", None)
        ex = m.get("extensions", {}); ex.pop("KHR_materials_specular", None); ex.pop("KHR_materials_ior", None)
        if not ex: m.pop("extensions", None)
    used = {k for m in j.get("materials", []) for k in m.get("extensions", {})}
    if "extensionsUsed" in j:
        j["extensionsUsed"] = [e for e in j["extensionsUsed"] if e in used or not e.startswith("KHR_materials")]
        if not j["extensionsUsed"]: j.pop("extensionsUsed")
    js = json.dumps(j, separators=(",", ":")).encode(); js += b" " * ((4 - len(js) % 4) % 4)
    out = b"glTF" + struct.pack("<II", 2, 12 + 8 + len(js) + len(rest)) + struct.pack("<I", len(js)) + b"JSON" + js + rest
    open(path, "wb").write(out)
def export(path):
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", export_image_format="AUTO", export_animations=bool(arm), export_animation_mode="ACTIONS")
    patch_glb(path)
export(dst)
tris = sum(len(p.vertices) - 2 for o in ms for p in o.data.polygons)
pts = world_pts(); lo = Vector([min(p[i] for p in pts) for i in range(3)]); hi = Vector([max(p[i] for p in pts) for i in range(3)])
print("FIT_DONE", dst, "dims_xyz(m,Blender)", [round(x, 2) for x in (hi - lo)], "tris", tris, "anims", [x.name for x in bpy.data.actions])
for vname, hue in VAR.items():
    for im in imgs:
        px = base[im.name].copy(); rgb = px[:, :3]
        mx = rgb.max(1); mn = rgb.min(1); sat = np.where(mx > 0, (mx - mn) / np.maximum(mx, 1e-6), 0)
        sel = sat > 0.25
        out = rgb.copy()
        if hue is None:
            lum = (rgb * [0.299, 0.587, 0.114]).sum(1); out[sel] = (lum[sel, None] * 0.8).repeat(3, 1)
        else:
            for i in np.nonzero(sel)[0]:
                h, l, s_ = colorsys.rgb_to_hls(*rgb[i]); out[i] = colorsys.hls_to_rgb(hue / 360, l, s_)
        px[:, :3] = out; im.pixels.foreach_set(px.ravel()); im.update()
    vd = "/".join(dst.replace("\\", "/").split("/")[:-2]) + f"/{vname}/{vname}.glb"
    import os; os.makedirs(os.path.dirname(vd), exist_ok=True); export(vd); print("VARIANT_DONE", vd)
