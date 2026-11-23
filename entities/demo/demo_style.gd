extends RefCounted

const SOURCE = preload("res://world/style_test/style_test.tscn")
const PAINT = preload("res://shaders/painted_gradient.gdshader")
var scene: Node3D
var tree: Node3D
var rock: MeshInstance3D

func install(parent: Node3D) -> Dictionary:
	scene = SOURCE.instantiate()
	parent.add_child(scene)
	scene.get_node("Camera3D").queue_free()
	var overlay := scene.get_node_or_null("Vignette/Overlay") as Control
	if overlay: overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tree = scene.get_node("Trees/Tree0")
	rock = scene.get_node("Rocks/Rock0")
	return {"sun": scene.get_node("Sun"), "environment": scene.get_node("WorldEnvironment").environment}

func decorate(visual: Node3D, kind: String, category: String) -> Node3D:
	if category == "nodes" and kind == "tree":
		visual.free()
		visual = tree.duplicate()
		visual.position = Vector3.ZERO
		visual.scale = Vector3.ONE
	elif category == "nodes" and kind in ["rock", "spirit_rock"]:
		visual.free()
		visual = Node3D.new()
		var stone := rock.duplicate() as MeshInstance3D
		stone.position = Vector3(0, 0.6, 0)
		visual.add_child(stone)
	if category != "players": _paint(visual)
	return visual

func _paint(node: Node) -> void:
	if node is MeshInstance3D:
		if node.material_override is ShaderMaterial:
			node.material_override = node.material_override.duplicate()
		elif node.material_override is StandardMaterial3D:
			var color: Color = node.material_override.albedo_color
			var material := ShaderMaterial.new()
			material.shader = PAINT
			material.set_shader_parameter("top_color", color.lerp(Color("a99b72"), 0.25))
			material.set_shader_parameter("bottom_color", color.darkened(0.48))
			material.set_shader_parameter("gradient_start", -1.0)
			material.set_shader_parameter("gradient_height", 2.0)
			material.set_shader_parameter("shade_floor", 0.28)
			node.material_override = material
	for child in node.get_children(): _paint(child)
