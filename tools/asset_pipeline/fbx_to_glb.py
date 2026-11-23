"""Blender: chuyển một FBX có xương + hoạt ảnh sang GLB, đưa về mét, pivot tâm đáy.
blender -b -P fbx_to_glb.py -- <in.fbx> <out.glb> [chiều dài mục tiêu theo trục dài nhất, mét]"""
import bpy, sys, mathutils
a = sys.argv[sys.argv.index("--") + 1:]
src, dst = a[0], a[1]; target = float(a[2]) if len(a) > 2 else 0
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=src, automatic_bone_orientation=True)
meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
dg = bpy.context.evaluated_depsgraph_get()
pts = [o.matrix_world @ v.co for o in meshes for v in o.data.vertices]
mn = mathutils.Vector([min(p[i] for p in pts) for i in range(3)]); mx = mathutils.Vector([max(p[i] for p in pts) for i in range(3)])
size = mx - mn
roots = [o for o in bpy.context.scene.objects if o.parent is None]
k = target / max(size) if target else 1.0
for r in roots:
    r.scale = r.scale * k
    r.location = (r.location - mathutils.Vector(((mn.x + mx.x) / 2, (mn.y + mx.y) / 2, mn.z))) * k
print("SIZE_BEFORE", tuple(round(x, 3) for x in size), "SCALE", round(k, 5))
print("ACTIONS", [ac.name for ac in bpy.data.actions])
bpy.ops.export_scene.gltf(filepath=dst, export_format="GLB", export_animations=True, export_animation_mode="ACTIONS", export_apply=False)
print("GLB_DONE", dst)
