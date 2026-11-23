extends GutTest

const ModelLib = preload("res://entities/view/model_library.gd")
const Shapes = preload("res://entities/view/entity_meshes.gd")
const WorldStyle = preload("res://entities/view/world_style.gd")
const WorldView = preload("res://entities/view/world_view.gd")


func test_all_mapped_glbs_exist_and_load() -> void:
	var paths := ModelLib.all_paths()
	assert_gt(paths.size(), 50, "ModelLib should map at least 50 unique GLB models")
	for path in paths:
		assert_true(ResourceLoader.exists(path), "Missing GLB resource: %s" % path)
		var scene := ModelLib.load_scene(path)
		assert_not_null(scene, "Failed to load PackedScene: %s" % path)


func test_entities_instantiate_glb_and_fallback() -> void:
	var cases := [
		["player", "players", {"character": "beast_bloodline"}],
		["wolf", "creatures", {}],
		["rabbit", "creatures", {}],
		["monkey", "creatures", {}],
		["tree", "nodes", {}],
		["rock", "nodes", {}],
		["spirit_rock", "nodes", {}],
		["berry_bush", "nodes", {}],
		["twig_bush", "nodes", {}],
		["herb", "nodes", {}],
		["spring", "nodes", {}],
		["rabbit_den", "nodes", {}],
		["wolf_den", "nodes", {}],
		["monkey_den", "nodes", {}],
		["flint", "nodes", {}],
		["mushroom", "nodes", {}],
		["campfire", "structures", {}],
		["firepit", "structures", {}],
		["workbench", "structures", {}],
		["chest", "structures", {}],
		["cooking_pot", "structures", {}],
		["alchemy_furnace", "structures", {}],
		["farm", "structures", {}],
		["resurrection_altar", "structures", {}],
		["drop", "drops", {"id": "wood"}],
		["drop", "drops", {"id": "spear"}],
		["drop", "drops", {"id": "blood_pill"}],
		["boss_flame_wolf", "creatures", {}],
		["carrion_crow", "creatures", {}],
		["bamboo", "nodes", {}],
		["mud", "nodes", {}],
		["talisman_desk", "structures", {}],
		["puppet_chop", "puppets", {}],
		["drop", "drops", {"id": "frost_talisman"}],
		["drop", "drops", {"id": "imprint_frost_wyrm"}],
	]
	for c in cases:
		var node := Shapes.create(c[0], c[1], c[2])
		assert_not_null(node, "Shapes.create returned null for %s/%s" % [c[1], c[0]])
		assert_true(bool(node.get_meta("has_glb", false)), "Expected GLB for %s/%s" % [c[1], c[0]])
		node.free()

	for fb in [["no_such_beast", "creatures", {}], ["puppet_unknown", "puppets", {}], ["no_such_node", "nodes", {}]]:
		var node := Shapes.create(fb[0], fb[1], fb[2])
		assert_not_null(node, "Fallback returned null for %s/%s" % [fb[1], fb[0]])
		assert_false(bool(node.get_meta("has_glb", false)), "Expected primitive fallback for %s/%s" % [fb[1], fb[0]])
		node.free()


func test_creature_glbs_have_animations() -> void:
	for kind in ["wolf", "rabbit", "monkey"]:
		var node := Shapes.create(kind, "creatures", {})
		var ap := node.get_meta("anim_player", null) as AnimationPlayer
		assert_not_null(ap, "Creature %s should have AnimationPlayer" % kind)
		if ap != null:
			for anim_name in ["idle", "walk", "run"]:
				assert_true(ap.has_animation(anim_name), "Creature %s missing animation '%s'" % [kind, anim_name])
		node.free()


func test_world_style_preserves_glb_trees_and_rocks() -> void:
	var root := Node3D.new()
	add_child_autofree(root)
	var style := WorldStyle.new()
	style.install(root)
	for kind in ["tree", "rock", "spirit_rock"]:
		var visual := Shapes.create(kind, "nodes", {})
		var decorated := style.decorate(visual, kind, "nodes")
		assert_eq(decorated, visual, "WorldStyle.decorate should preserve GLB node for %s" % kind)
		assert_true(bool(decorated.get_meta("has_glb", false)), "Decorated %s should keep has_glb" % kind)
		decorated.free()


func test_world_view_renders_glb_state_without_error() -> void:
	var view := WorldView.new()
	add_child_autofree(view)
	var state := {
		"seed": 42,
		"options": {"map_size": 80.0},
		"clock": {"phase": "day", "season": "autumn"},
		"weather": {"kind": "clear", "warnings": []},
		"karma": {"sin": 0.0, "fate": 0.0},
		"players": {
			"1": {"uid": 1, "name": "P1", "character": "beast_bloodline", "position": [0.0, 0.0, 0.0], "ghost": false, "hit_flash": 0.0, "sense_time": 1.0, "stats": {"dao": 100.0}, "effects": {}, "inventory": {"equipment": {}}},
			"2": {"uid": 2, "name": "P2", "character": "beast_bloodline", "position": [2.0, 0.0, 0.0], "ghost": true, "hit_flash": 0.0, "stats": {"dao": 100.0}, "effects": {}, "inventory": {"equipment": {}}},
			"3": {"uid": 3, "name": "P3", "character": "beast_bloodline", "position": [-2.0, 0.0, 0.0], "ghost": false, "hit_flash": 0.2, "stats": {"dao": 100.0}, "effects": {}, "inventory": {"equipment": {}}},
		},
		"nodes": [
			{"uid": 10, "kind": "tree", "position": [4.0, 0.0, 0.0], "regrow": 0.0, "stage": 0},
			{"uid": 11, "kind": "rock", "position": [6.0, 0.0, 0.0], "regrow": 0.0, "stage": 0},
		],
		"creatures": [
			{"uid": 20, "kind": "wolf", "state": "chase", "position": [5.0, 0.0, 2.0]},
			{"uid": 21, "kind": "rabbit", "state": "wander", "position": [3.0, 0.0, 2.0]},
			{"uid": 22, "kind": "monkey", "state": "idle", "position": [1.0, 0.0, 3.0]},
		],
		"structures": [
			{"uid": 30, "kind": "campfire", "position": [0.0, 0.0, 4.0], "fuel": 50.0},
			{"uid": 31, "kind": "firepit", "position": [2.0, 0.0, 4.0], "fuel": 0.0},
		],
		"drops": [
			{"uid": 40, "kind": "drop", "id": "wood", "count": 1, "position": [-1.0, 0.0, 1.0]},
		],
		"puppets": [],
		"npcs": [],
	}
	view.render(state, 1)
	state.creatures[0].position = [6.0, 0.0, 3.0]
	view.render(state, 1)
	view._process(0.1)

	var wolf_vis: Node3D = view.visuals.get("creatures20")
	assert_not_null(wolf_vis)
	var wolf_ap := wolf_vis.get_meta("anim_player", null) as AnimationPlayer
	assert_not_null(wolf_ap)
	assert_eq(wolf_ap.current_animation, "run")

	var campfire_vis: Node3D = view.visuals.get("structures30")
	assert_not_null(campfire_vis)
	var flame := campfire_vis.get_node_or_null("FireFlame") as MeshInstance3D
	assert_not_null(flame)
	assert_true(flame.visible)

	var firepit_vis: Node3D = view.visuals.get("structures31")
	assert_not_null(firepit_vis)
	var pit_flame := firepit_vis.get_node_or_null("FireFlame") as MeshInstance3D
	assert_not_null(pit_flame)
	assert_false(pit_flame.visible)

	var p2_vis: Node3D = view.visuals.get("players2")
	var p2_shadow := p2_vis.get_node_or_null("ContactShadow") as MeshInstance3D
	assert_not_null(p2_shadow, "GLB player should have ContactShadow")
	assert_null(p2_shadow.material_overlay, "ContactShadow should not receive ghost/hit overlay")
	var p2_meshes := p2_vis.find_children("*", "MeshInstance3D", true, false)
	var overlaid := 0
	for m in p2_meshes:
		var mi := m as MeshInstance3D
		if mi != null and mi.name != "ContactShadow" and mi.material_overlay != null:
			overlaid += 1
	assert_gt(overlaid, 0)


func test_glb_materials_are_non_metallic() -> void:
	var cases := [
		["player", "players", {"character": "beast_bloodline"}],
		["tree", "nodes", {}],
		["rock", "nodes", {}],
		["wolf", "creatures", {}],
		["campfire", "structures", {}],
		["drop", "drops", {"id": "wood"}],
	]
	for c in cases:
		var node := Shapes.create(c[0], c[1], c[2])
		var meshes := node.find_children("*", "MeshInstance3D", true, false)
		assert_gt(meshes.size(), 0, "Expected meshes for %s/%s" % [c[1], c[0]])
		for m in meshes:
			var mi := m as MeshInstance3D
			if mi == null or mi.name == "ContactShadow" or mi.mesh == null:
				continue
			for i in mi.mesh.get_surface_count():
				var mat := mi.get_active_material(i) as StandardMaterial3D
				if mat != null:
					assert_eq(mat.metallic, 0.0, "GLB %s/%s should have metallic == 0" % [c[1], c[0]])
					assert_eq(mat.metallic_specular, 0.0, "GLB %s/%s should have metallic_specular == 0" % [c[1], c[0]])
					assert_eq(mat.diffuse_mode, BaseMaterial3D.DIFFUSE_LAMBERT_WRAP, "GLB %s/%s should use DIFFUSE_LAMBERT_WRAP" % [c[1], c[0]])
		node.free()
