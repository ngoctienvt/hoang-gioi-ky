extends RefCounted

const ModelLib = preload("res://entities/view/model_library.gd")

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

static func create(kind: String, category: String, entity: Dictionary = {}) -> Node3D:
	var glb := ModelLib.instantiate(kind, category, entity)
	if glb != null:
		return glb
	var node := Node3D.new()
	var green := Color("3c7652")
	var wood := Color("795036")
	if category == "players":
		var cid := str(entity.get("character", "beast_bloodline"))
		if cid.is_empty():
			cid = "beast_bloodline"
		var cpath := "res://data/characters/%s.tres" % cid
		var cdef = load(cpath) if ResourceLoader.exists(cpath) else null
		var body_col: Color = cdef.body_color if cdef != null else Color("a74f3f")
		cylinder(node, body_col, Vector3(0, 0.65, 0), 0.31, 0.9)
		ball(node, Color("ddba8c"), Vector3(0, 1.3, 0), Vector3(0.48, 0.55, 0.48))
		ball(node, Color("302b2a"), Vector3(0, 1.57, 0), Vector3(0.5, 0.18, 0.5))
	elif category == "creatures":
		if kind == "heart_demon":
			ball(node, Color(0.03, 0.03, 0.04, 1.0), Vector3(0, 0.85, 0), Vector3(0.75, 1.35, 0.75))
			ball(node, Color(0.95, 0.95, 0.98, 0.25), Vector3(0, 0.85, 0), Vector3(0.98, 1.6, 0.98))
		elif kind == "wraith":
			cylinder(node, Color(0.45, 0.72, 0.78, 0.65), Vector3(0, 0.8, 0), 0.35, 1.4)
			ball(node, Color(0.75, 0.95, 0.98, 0.75), Vector3(0, 1.55, 0), Vector3(0.45, 0.45, 0.45))
		else:
			_create_creature(node, kind)
	elif category == "puppets":
		var is_guard := kind == "puppet_guard"
		var pcol := Color("434d59") if is_guard else Color("8b6f47") if "chop" in kind else Color("6a737d") if "mine" in kind else Color("a6885c")
		var body_box := BoxMesh.new()
		body_box.size = Vector3(0.65, 0.85, 0.55)
		mesh(node, body_box, pcol, Vector3(0, 0.55, 0))
		ball(node, Color("e65a4f") if is_guard else Color("5cd6c8"), Vector3(0, 1.15, 0), Vector3(0.4, 0.4, 0.4))
	elif category == "npcs":
		var ncol := Color("8c3838") if "evil" in kind else Color("385a8c") if "enforcer" in kind else Color("c8a45c") if "merchant" in kind else Color("6c8a6c")
		cylinder(node, ncol, Vector3(0, 0.65, 0), 0.3, 1.0)
		ball(node, Color("e3c298"), Vector3(0, 1.32, 0), Vector3(0.46, 0.5, 0.46))
	elif category == "drops":
		ball(node, Color("d5b061"), Vector3(0, 0.2, 0), Vector3(0.4, 0.35, 0.4))
	elif kind == "teleport_array":
		cylinder(node, Color("666156"), Vector3(0, 0.08, 0), 1.8, 0.16)
		var ring_col := Color("5cd6c8") if str(entity.get("state", "dormant")) == "active" else Color("4a4a50")
		cylinder(node, ring_col, Vector3(0, 0.18, 0), 1.2, 0.06)
	elif kind == "mud":
		cylinder(node, Color("3b332a"), Vector3(0, 0.02, 0), 1.4, 0.04)
	elif kind == "floor_trap":
		var box := BoxMesh.new()
		box.size = Vector3(1.2, 0.06, 1.2)
		mesh(node, box, Color("6c5848"), Vector3(0, 0.03, 0))
	elif kind == "ruin_path":
		var slab := BoxMesh.new()
		slab.size = Vector3(1.8, 0.04, 1.8)
		mesh(node, slab, Color("5a554c"), Vector3(0, 0.02, 0))
	elif kind == "altar":
		cylinder(node, Color("8a8275"), Vector3(0, 0.25, 0), 1.1, 0.5)
		cylinder(node, Color("d4b668"), Vector3(0, 0.55, 0), 0.6, 0.12)
	elif kind == "seal_stone":
		cylinder(node, Color("524a62"), Vector3(0, 0.9, 0), 0.45, 1.8)
		ball(node, Color("b85cd6"), Vector3(0, 1.9, 0), Vector3(0.35, 0.35, 0.35))
	elif kind == "sect_ore":
		ball(node, Color("4b5d78"), Vector3(0, 0.65, 0), Vector3(1.6, 1.5, 1.4))
		ball(node, Color("76c7e8"), Vector3(0.25, 1.1, 0), Vector3(0.45, 0.45, 0.45))
	elif kind == "secret_realm_portal":
		cylinder(node, Color("3c2d5c"), Vector3(0, 1.2, 0), 1.1, 2.4)
		ball(node, Color("7ee8fa"), Vector3(0, 1.2, 0), Vector3(0.9, 1.8, 0.25))
	elif kind == "secret_realm_exit":
		cylinder(node, Color("485c4a"), Vector3(0, 1.2, 0), 1.1, 2.4)
		ball(node, Color("9ef7b0"), Vector3(0, 1.2, 0), Vector3(0.9, 1.8, 0.25))
	elif kind == "realm_switch":
		cylinder(node, Color("5c556a"), Vector3(0, 0.9, 0), 0.35, 1.8)
		ball(node, Color("f0c659") if entity.get("active", false) else Color("4a6e7a"), Vector3(0, 2.0, 0), Vector3(0.45, 0.45, 0.45))
	elif kind == "realm_chest":
		var box := BoxMesh.new()
		box.size = Vector3(1.1, 0.8, 0.8)
		mesh(node, box, Color("d4b668") if entity.get("unlocked", false) else Color("4d433b"), Vector3(0, 0.4, 0))
	elif "bamboo" in kind:
		for offset in [Vector3(-0.25, 0, 0), Vector3(0.2, 0, 0.2), Vector3(0, 0, -0.2)]:
			cylinder(node, Color("67904e"), offset + Vector3(0, 1.5, 0), 0.09, 3)
			ball(node, green, offset + Vector3(0, 2.8, 0), Vector3(1.3, 0.65, 1.2))
	elif "tree" in kind or "pine" in kind:
		var trunk_col := Color("3b3532") if "charred" in kind else Color("54493c") if "rotten" in kind else wood
		var leaf_col := Color("5c4239") if "charred" in kind else Color("526149") if "rotten" in kind else Color("7ba0a8") if "snow" in kind else green
		cylinder(node, trunk_col, Vector3(0, 1.1, 0), 0.25, 2.2)
		ball(node, leaf_col, Vector3(0, 2.6, 0), Vector3(2.4, 2.1, 2.2))
		ball(node, Color("88735c") if "dead" in kind else leaf_col.lightened(0.08), Vector3(0.6, 2.9, 0.2), Vector3(1.5, 1.7, 1.6))
	elif "rock" in kind or "stone" in kind or "ore" in kind or "vein" in kind or "boulder" in kind or "pillar" in kind or "crystal" in kind:
		var rock_col := Color("7a84a2") if "spirit" in kind or "rune" in kind else Color("9e493b") if "cinnabar" in kind or "magma" in kind else Color("5a7d99") if "ice" in kind or "eternal" in kind else Color("6874a6") if "thunder" in kind else Color("4a4545") if "basalt" in kind or "iron" in kind else Color("8c897d")
		ball(node, rock_col, Vector3(0, 0.6, 0), Vector3(1.7, 1.6, 1.4))
	elif "spring" in kind:
		var water_colors := {
			"thanh_moc": Color("6dd2bd"),
			"u_minh": Color("7d6aa6"),
			"xich_viem": Color("e06a3b"),
			"loi_tri": Color("78c8e6"),
			"huyen_bang": Color("a5e3f2"),
			"co_van": Color("d6b467"),
		}
		var wcol: Color = water_colors.get(str(entity.get("water_type", "thanh_moc")), Color("6dd2bd"))
		if entity.get("frozen", false):
			wcol = Color("b9e6f2")
		cylinder(node, Color("628d8a"), Vector3(0, 0.05, 0), 1.6, 0.15)
		cylinder(node, wcol, Vector3(0, 0.14, 0), 1.25, 0.08)
	elif kind == "ice_structure":
		var ice_box := BoxMesh.new()
		ice_box.size = Vector3(1.1, 1.2, 1.1)
		mesh(node, ice_box, Color("8fd3e8"), Vector3(0, 0.6, 0))
	elif kind == "ice_cellar":
		var base := BoxMesh.new()
		base.size = Vector3(1.8, 1.3, 1.8)
		mesh(node, base, Color("67849c"), Vector3(0, 0.65, 0))
		var cap := BoxMesh.new()
		cap.size = Vector3(1.5, 0.3, 1.5)
		mesh(node, cap, Color("a9e2f2"), Vector3(0, 1.4, 0))
	elif kind == "lightning_rod":
		cylinder(node, Color("5a5d66"), Vector3(0, 0.2, 0), 0.6, 0.4)
		cylinder(node, Color("485970"), Vector3(0, 1.3, 0), 0.12, 2.2)
		ball(node, Color("7ee0ff"), Vector3(0, 2.5, 0), Vector3(0.28, 0.35, 0.28))
	elif "fire" in kind:
		cylinder(node, Color("68625c"), Vector3(0, 0.13, 0), 0.65, 0.3)
		ball(node, Color("ffae48"), Vector3(0, 0.55, 0), Vector3(0.65, 1.1, 0.65))
	elif category == "structures":
		if kind == "stake":
			cylinder(node, wood, Vector3(0, 0.6, 0), 0.12, 1.2)
			ball(node, Color("5cd6c8"), Vector3(0, 1.25, 0), Vector3(0.28, 0.28, 0.28))
			return node
		if kind in ["soul_lantern", "light_pillar"]:
			cylinder(node, Color("4f5866"), Vector3(0, 0.9, 0), 0.18, 1.8)
			ball(node, Color("74f2ce") if kind == "soul_lantern" else Color("ffdf7a"), Vector3(0, 1.9, 0), Vector3(0.45, 0.45, 0.45))
			return node
		if kind == "water_array":
			cylinder(node, Color("5f7c8a"), Vector3(0, 0.15, 0), 1.1, 0.3)
			ball(node, Color("6dd2bd"), Vector3(0, 0.5, 0), Vector3(0.5, 0.5, 0.5))
			return node
		var shape := BoxMesh.new()
		shape.size = Vector3(1.4, 0.7, 1)
		var scol := Color("5a3e5e") if kind == "talisman_chest" else Color("7c4738") if kind == "refining_forge" else Color("4a6375") if kind == "talisman_desk" else wood
		mesh(node, shape, scol, Vector3(0, 0.4, 0))
		if kind in ["crafting_table", "workbench", "craft_table", "shanmen", "talisman_desk", "refining_forge", "awakening_altar", "guest_altar"]:
			for x in [-0.6, 0.6]: cylinder(node, scol, Vector3(x, 1.2, 0), 0.1, 2.4)
			var roof := BoxMesh.new()
			roof.size = Vector3(1.9, 0.2, 1.3)
			mesh(node, roof, Color("405668"), Vector3(0, 2.3, 0))
	elif "grass" in kind or "twig" in kind:
		for x in [-0.2, 0.0, 0.2]: cylinder(node, green if "grass" in kind else wood, Vector3(x, 0.3, x), 0.07, 0.6)
	else:
		ball(node, green, Vector3(0, 0.5, 0), Vector3(0.9, 0.8, 0.9))
		ball(node, Color("ba5c67"), Vector3(0.2, 0.8, -0.2), Vector3(0.25, 0.25, 0.25))
	return node


static func _eye(parent: Node3D, at: Vector3, color: Color) -> void:
	var shape := SphereMesh.new()
	shape.radial_segments = 6
	shape.rings = 3
	var m := mesh(parent, shape, color, at)
	m.scale = Vector3(0.11, 0.11, 0.11)
	var mat := m.material_override as StandardMaterial3D
	if mat:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 1.6


static func _create_creature(node: Node3D, kind: String) -> void:
	var palette := {
		"rabbit": Color("a898b9"), "spirit_rabbit": Color("a898b9"),
		"wolf": Color("576176"), "ice_wolf": Color("7d98b3"),
		"monkey": Color("a37d49"), "spirit_monkey": Color("a37d49"),
		"forest_pheasant": Color("9b6346"), "spirit_leech": Color("4a5743"),
		"carrion_crow": Color("2f333a"), "jiangshi": Color("566e64"),
		"lava_lizard": Color("9e4433"), "fire_bird": Color("cf6a3a"),
		"thunder_beast": Color("546994"), "stone_golem": Color("65686e"),
		"snow_bear": Color("c9d4db"), "thick_fur_beast": Color("8b7d72"),
		"construct_beast": Color("827556"), "ruin_wraith": Color("61858d"),
	}
	var eye_colors := {
		"wolf": Color("ffd166"), "ice_wolf": Color("8be9fd"),
		"jiangshi": Color("9bf078"), "lava_lizard": Color("ff9f43"),
		"fire_bird": Color("ffbe55"), "thunder_beast": Color("7ee0ff"),
		"stone_golem": Color("7ee0ff"), "construct_beast": Color("f3c969"),
		"ruin_wraith": Color("84f5df"), "spirit_leech": Color("d96b6b"),
	}
	var col: Color = palette.get(kind, Color("8c8276"))
	var eye_col: Color = eye_colors.get(kind, Color("f0e2b6"))

	if kind.begins_with("boss_"):
		var boss_cols := {
			"boss_ghost_general": Color("475b69"),
			"boss_flame_wolf": Color("a8402d"),
			"boss_iron_turtle": Color("586452"),
			"boss_thunder_roc": Color("4e5e99"),
			"boss_frost_wyrm": Color("7ab5cc"),
			"boss_ancient_warden": Color("6e624b"),
		}
		var bcol: Color = boss_cols.get(kind, Color("8a3b3b"))
		var bbody := BoxMesh.new()
		bbody.size = Vector3(1.8, 2.1, 1.8)
		mesh(node, bbody, bcol, Vector3(0, 1.1, 0))
		ball(node, bcol.lightened(0.15), Vector3(0, 2.4, -0.35), Vector3(1.0, 0.9, 1.0))
		for x in [-0.25, 0.25]:
			_eye(node, Vector3(x, 2.5, -0.82), Color("ff5c4d"))
		return
	if kind in ["stone_golem", "snow_bear"]:
		var s := 1.45 if kind == "stone_golem" else 1.25
		var body := BoxMesh.new()
		body.size = Vector3(1.1 * s, 1.2 * s, 1.1 * s)
		mesh(node, body, col, Vector3(0, 0.7 * s, 0))
		ball(node, col.lightened(0.08), Vector3(0, 1.35 * s, -0.35 * s), Vector3(0.65 * s, 0.55 * s, 0.65 * s))
		for x in [-0.16 * s, 0.16 * s]:
			_eye(node, Vector3(x, 1.4 * s, -0.68 * s), eye_col)
	elif kind in ["forest_pheasant", "carrion_crow", "fire_bird"]:
		ball(node, col, Vector3(0, 0.75, 0), Vector3(0.55, 0.45, 0.75))
		ball(node, col.lightened(0.12), Vector3(0, 0.95, -0.38), Vector3(0.32, 0.32, 0.32))
		for x in [-0.38, 0.38]:
			var wing := BoxMesh.new()
			wing.size = Vector3(0.45, 0.08, 0.35)
			mesh(node, wing, col.darkened(0.15), Vector3(x, 0.8, 0))
		for x in [-0.1, 0.1]:
			_eye(node, Vector3(x, 0.98, -0.52), eye_col)
	elif kind == "spirit_leech":
		cylinder(node, col, Vector3(0, 0.15, 0), 0.32, 0.25)
		ball(node, col.darkened(0.15), Vector3(0, 0.22, -0.25), Vector3(0.4, 0.25, 0.55))
		_eye(node, Vector3(0, 0.28, -0.48), eye_col)
	elif kind in ["jiangshi", "ruin_wraith"]:
		cylinder(node, col, Vector3(0, 0.75, 0), 0.34, 1.2)
		ball(node, col.lightened(0.1), Vector3(0, 1.45, 0), Vector3(0.48, 0.52, 0.48))
		for x in [-0.12, 0.12]:
			_eye(node, Vector3(x, 1.48, -0.23), eye_col)
	elif kind == "construct_beast":
		var hull := BoxMesh.new()
		hull.size = Vector3(0.95, 0.7, 1.15)
		mesh(node, hull, col, Vector3(0, 0.6, 0))
		cylinder(node, Color("5cd6c8"), Vector3(0, 1.0, 0), 0.25, 0.2)
		for x in [-0.2, 0.2]:
			_eye(node, Vector3(x, 0.72, -0.58), eye_col)
	else:
		ball(node, col, Vector3(0, 0.45, 0), Vector3(0.7, 0.6, 1.0))
		ball(node, col.lightened(0.12), Vector3(0, 0.7, -0.45), Vector3(0.5, 0.5, 0.5))
		for x in [-0.17, 0.17]:
			cylinder(node, col, Vector3(x, 1.02, -0.43), 0.08, 0.6 if "rabbit" in kind else 0.25)
			_eye(node, Vector3(x * 0.8, 0.75, -0.68), eye_col)
