import bpy, sys
a = sys.argv[sys.argv.index("--") + 1:]
bpy.ops.wm.open_mainfile(filepath=a[0])
print("ACTIONS", [(ac.name, int(ac.frame_range[1]-ac.frame_range[0])) for ac in bpy.data.actions])
