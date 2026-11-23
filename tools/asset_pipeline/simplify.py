"""Buoc 4a: mesh Paint (40k, UV nhieu seam) -> han dinh theo vi tri -> giam quadric (fast_simplification) -> low.glb khong UV.
python simplify.py SRC.glb LOW.glb TRIS"""
import sys, numpy as np, trimesh, fast_simplification
src, dst, T = sys.argv[1], sys.argv[2], int(sys.argv[3])
m = trimesh.load(src, force="mesh")
m = trimesh.Trimesh(m.vertices, m.faces, process=False); m.merge_vertices(); m.remove_unreferenced_vertices()
if len(m.faces) > T:
    v, f = fast_simplification.simplify(m.vertices.astype(np.float32), m.faces.astype(np.int64), target_reduction=1 - T / len(m.faces))
    m = trimesh.Trimesh(v, f, process=False)
m.export(dst); print("SIMPLIFY", src, len(m.faces))
