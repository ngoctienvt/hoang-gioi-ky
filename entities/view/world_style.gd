extends RefCounted

const SOURCE = preload("res://world/style_test/style_test.tscn")
const PAINT = preload("res://shaders/painted_gradient.gdshader")
const INK_VIGNETTE = preload("res://shaders/ink_vignette.gdshader")
var scene: Node3D
var tree: Node3D
var rock: MeshInstance3D
var ink_overlay: ColorRect

func install(parent: Node3D) -> Dictionary:
	scene = SOURCE.instantiate()
	parent.add_child(scene)
	scene.get_node("Camera3D").queue_free()
	var overlay := scene.get_node_or_null("Vignette/Overlay") as Control
	if overlay: overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tree = scene.get_node("Trees/Tree0")
	rock = scene.get_node("Rocks/Rock0")
	for child in scene.get_children():
		if not child.name in ["WorldEnvironment", "Sun", "Vignette"] and child is Node3D:
			child.visible = false
	var env: Environment = scene.get_node("WorldEnvironment").environment
	env.fog_depth_begin = 28.0
	env.fog_depth_end = 95.0
	var vig_layer := scene.get_node_or_null("Vignette")
	if vig_layer != null:
		ink_overlay = ColorRect.new()
		ink_overlay.name = "InkOverlay"
		ink_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		ink_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var mat := ShaderMaterial.new()
		mat.shader = INK_VIGNETTE
		mat.set_shader_parameter("intensity", 0.0)
		ink_overlay.material = mat
		vig_layer.add_child(ink_overlay)
	return {"sun": scene.get_node("Sun"), "environment": env, "ink_overlay": ink_overlay}

func decorate(visual: Node3D, kind: String, category: String) -> Node3D:
	if category == "nodes" and kind == "tree":
		visual.free()
		visual = tree.duplicate()
		visual.visible = true
		visual.position = Vector3.ZERO
		visual.scale = Vector3.ONE
	elif category == "nodes" and kind in ["rock", "spirit_rock"]:
		visual.free()
		visual = Node3D.new()
		var stone := rock.duplicate() as MeshInstance3D
		stone.visible = true
		stone.position = Vector3(0, 0.6, 0)
		visual.add_child(stone)
	if category != "players" and kind != "heart_demon": _paint(visual)
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
