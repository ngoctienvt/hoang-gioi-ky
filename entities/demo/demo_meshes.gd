extends RefCounted

static func mesh(parent: Node3D, shape: PrimitiveMesh, color: Color, at: Vector3) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = shape
	node.position = at
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.95
	if color.a < 1:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	node.material_override = material
	parent.add_child(node)
	return node

static func ball(parent: Node3D, color: Color, at: Vector3, scale: Vector3) -> MeshInstance3D:
	var shape := SphereMesh.new()
	shape.radial_segments = 8
	shape.rings = 4
	var node := mesh(parent, shape, color, at)
	node.scale = scale
	return node

static func cylinder(parent: Node3D, color: Color, at: Vector3, radius: float, height: float) -> MeshInstance3D:
	var shape := CylinderMesh.new()
	shape.top_radius = radius * 0.8
	shape.bottom_radius = radius
	shape.height = height
	shape.radial_segments = 7
	return mesh(parent, shape, color, at)

static func create(kind: String, category: String) -> Node3D:
	var node := Node3D.new()
	var green := Color("3c7652")
	var wood := Color("795036")
	if category == "players":
		cylinder(node, Color("a74f3f"), Vector3(0, 0.65, 0), 0.31, 0.9)
		ball(node, Color("ddba8c"), Vector3(0, 1.3, 0), Vector3(0.48, 0.55, 0.48))
		ball(node, Color("302b2a"), Vector3(0, 1.57, 0), Vector3(0.5, 0.18, 0.5))
	elif category == "creatures":
		var color := Color("a898b9") if "rabbit" in kind else Color("576176") if "wolf" in kind else Color("a37d49")
		ball(node, color, Vector3(0, 0.45, 0), Vector3(0.7, 0.6, 1.0))
		ball(node, color.lightened(0.12), Vector3(0, 0.7, -0.45), Vector3(0.5, 0.5, 0.5))
		for x in [-0.17, 0.17]:
			cylinder(node, color, Vector3(x, 1.02, -0.43), 0.08, 0.6 if "rabbit" in kind else 0.25)
	elif category == "drops":
		ball(node, Color("d5b061"), Vector3(0, 0.2, 0), Vector3(0.4, 0.35, 0.4))
	elif "bamboo" in kind:
		for offset in [Vector3(-0.25, 0, 0), Vector3(0.2, 0, 0.2), Vector3(0, 0, -0.2)]:
			cylinder(node, Color("67904e"), offset + Vector3(0, 1.5, 0), 0.09, 3)
			ball(node, green, offset + Vector3(0, 2.8, 0), Vector3(1.3, 0.65, 1.2))
	elif "tree" in kind or "pine" in kind:
		cylinder(node, wood, Vector3(0, 1.1, 0), 0.25, 2.2)
		ball(node, green, Vector3(0, 2.6, 0), Vector3(2.4, 2.1, 2.2))
		ball(node, Color("88735c") if "dead" in kind else Color("567647"), Vector3(0.6, 2.9, 0.2), Vector3(1.5, 1.7, 1.6))
	elif "rock" in kind or "stone" in kind or "ore" in kind:
		ball(node, Color("7a84a2") if "spirit" in kind else Color("8c897d"), Vector3(0, 0.6, 0), Vector3(1.7, 1.6, 1.4))
	elif "spring" in kind:
		cylinder(node, Color("628d8a"), Vector3(0, 0.05, 0), 1.6, 0.15)
		cylinder(node, Color("6dd2bd"), Vector3(0, 0.14, 0), 1.25, 0.08)
	elif "fire" in kind:
		cylinder(node, Color("68625c"), Vector3(0, 0.13, 0), 0.65, 0.3)
		ball(node, Color("ffae48"), Vector3(0, 0.55, 0), Vector3(0.65, 1.1, 0.65))
	elif category == "structures":
		var shape := BoxMesh.new()
		shape.size = Vector3(1.4, 0.7, 1)
		mesh(node, shape, wood, Vector3(0, 0.4, 0))
		if kind in ["crafting_table", "workbench", "craft_table", "shanmen"]:
			for x in [-0.6, 0.6]: cylinder(node, wood, Vector3(x, 1.2, 0), 0.1, 2.4)
			var roof := BoxMesh.new()
			roof.size = Vector3(1.9, 0.2, 1.3)
			mesh(node, roof, Color("405668"), Vector3(0, 2.3, 0))
	elif "grass" in kind or "twig" in kind:
		for x in [-0.2, 0.0, 0.2]: cylinder(node, green if "grass" in kind else wood, Vector3(x, 0.3, x), 0.07, 0.6)
	else:
		ball(node, green, Vector3(0, 0.5, 0), Vector3(0.9, 0.8, 0.9))
		ball(node, Color("ba5c67"), Vector3(0.2, 0.8, -0.2), Vector3(0.25, 0.25, 0.25))
	return node
