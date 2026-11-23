"""Blender: chup anh xem truoc moi GLB tu goc camera game (nghieng 50 do, phia truoc ben phai), kem hinh nhan 1,7 m khi vat >= 0,8 m.
blender -b -P preview.py -- OUT_DIR GLB [GLB ...]   -> OUT_DIR/<ten>.png + OUT_DIR/stats.json"""
import bpy, sys, json, math, os
from mathutils import Vector
a = sys.argv[sys.argv.index("--") + 1:]; out = a[0]; os.makedirs(out, exist_ok=True)
sp = os.path.join(out, "stats.json"); stats = json.load(open(sp)) if os.path.exists(sp) else {}
for g in a[1:]:
    name = os.path.basename(g)[:-4]
    bpy.ops.wm.read_factory_settings(use_empty=True); sc = bpy.context.scene
    bpy.ops.import_scene.gltf(filepath=g)
    arm = [o for o in sc.objects if o.type == "ARMATURE"]
    for o in [o for o in sc.objects if o.type == "MESH"]:
        if arm and not any(md.type == "ARMATURE" for md in o.modifiers): bpy.data.objects.remove(o, do_unlink=True)  # Icosphere hinh xuong do importer tao
    ms = [o for o in sc.objects if o.type == "MESH"]
    dg = bpy.context.evaluated_depsgraph_get(); pts = []; tris = 0
    for o in ms:
        e = o.evaluated_get(dg); pts += [e.matrix_world @ v.co for v in e.data.vertices]; tris += sum(len(p.vertices) - 2 for p in e.data.polygons)
    lo = Vector([min(p[i] for p in pts) for i in range(3)]); hi = Vector([max(p[i] for p in pts) for i in range(3)]); sz = hi - lo
    if max(sz) >= 0.8:
        bpy.ops.mesh.primitive_cylinder_add(radius=0.22, depth=1.7, location=(hi.x + 0.5, (lo.y + hi.y) / 2, 0.85))
        r = bpy.context.object; m = bpy.data.materials.new("ref"); m.diffuse_color = (0.55, 0.55, 0.6, 1); r.data.materials.append(m)
        lo.x -= 0; hi.x += 0.8; hi.z = max(hi.z, 1.7)
    c = (lo + hi) / 2; rad = max((hi - lo).length / 2, 0.05)
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); sc.collection.objects.link(cam); sc.camera = cam
    cam.data.type = "ORTHO"; cam.data.ortho_scale = rad * 2.3
    el, az = math.radians(50), math.radians(25)
    d = Vector((math.sin(az) * math.cos(el), -math.cos(az) * math.cos(el), math.sin(el)))
    cam.location = c + d * rad * 6; cam.rotation_euler = (-d).to_track_quat("-Z", "Y").to_euler(); cam.data.clip_end = rad * 20
    sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN")); sc.collection.objects.link(sun); sun.data.energy = 3.0
    sun.rotation_euler = (math.radians(40), 0, math.radians(30))
    w = bpy.data.worlds.new("w"); sc.world = w; w.use_nodes = True; w.node_tree.nodes["Background"].inputs[0].default_value = (0.32, 0.32, 0.3, 1); w.node_tree.nodes["Background"].inputs[1].default_value = 1.0
    sc.render.engine = "BLENDER_EEVEE"; sc.render.resolution_x = sc.render.resolution_y = 420; sc.render.film_transparent = False
    sc.render.filepath = os.path.join(out, name + ".png"); bpy.ops.render.render(write_still=True)
    stats[name] = {"dims_xyz": [round(x, 2) for x in sz], "tris": tris, "anims": [x.name for x in bpy.data.actions]}
    print("PREVIEW", name, stats[name], flush=True)
json.dump(stats, open(sp, "w"), indent=1)
