extends GutTest

const GameUI = preload("res://ui/hud/game_ui.gd")
const PlayerControls = preload("res://world/player_controls.gd")

var world: GameWorld


func before_each() -> void:
	world = GameWorld.new()
	world.initialize(1234, {"all_dead": "continue"})
	world.clear_entities()
	world.add_player(1, "Host")


func _player() -> Dictionary:
	return world.state.players["1"]


func _give(id: String, count: int = 1) -> void:
	var inv = world.inventory(_player())
	assert_eq(inv.add_item(id, count), 0)
	_player().inventory = inv.to_dict()


func _count_item(id: String) -> int:
	return world.inventory(_player()).count_item(id)


func test_ui_signature_ignores_spoilage_subticks_and_tracks_changes() -> void:
	var ui = GameUI.new()
	add_child_autofree(ui)
	_give("spirit_fruit", 1)
	_give("talisman_paper", 1)
	var p := _player()
	var sig1: String = ui._ui_signature(world.state, p)

	# Sub-tick spoilage / paper soak changes must not invalidate the UI signature
	p.inventory.slots[0]["_f"] = 0.991
	p.inventory.slots[1]["soak"] = 0.123
	var sig2: String = ui._ui_signature(world.state, p)
	assert_eq(sig1, sig2)

	# Visible inventory changes must invalidate the signature
	p.inventory.slots[0]["freshness"] = 0.95
	var sig3: String = ui._ui_signature(world.state, p)
	assert_ne(sig2, sig3)

	# Discovered recipes and nearby stations must also invalidate the signature
	world.discover("flint_axe")
	var sig4: String = ui._ui_signature(world.state, p)
	assert_ne(sig3, sig4)

	var wb := world.entity("workbench", [1.0, 0.0, 0.0])
	world.add_entity("structures", wb)
	var sig5: String = ui._ui_signature(world.state, p)
	assert_ne(sig4, sig5)


func test_craft_flint_axe_and_flint_pickaxe() -> void:
	_give("twig", 4)
	_give("flint", 5)
	assert_true(world.action(1, "craft", {"recipe": "flint_axe"}))
	assert_true(world.action(1, "craft", {"recipe": "flint_pickaxe"}))
	assert_eq(_count_item("flint_axe"), 1)
	assert_eq(_count_item("flint_pickaxe"), 1)
	assert_eq(_count_item("twig"), 0)
	assert_eq(_count_item("flint"), 0)


func test_work_auto_equip_axe_and_pickaxe_from_inventory() -> void:
	var tree := world.entity("tree", [1.5, 0.0, 0.0])
	tree.merge({"stage": 0, "hits": 0, "depleted": false, "regrow": 0.0})
	world.add_entity("nodes", tree)

	var rock := world.entity("rock", [0.0, 0.0, 1.5])
	rock.merge({"stage": 0, "hits": 0, "depleted": false, "regrow": 0.0})
	world.add_entity("nodes", rock)

	_give("flint_axe", 1)
	_give("flint_pickaxe", 1)

	# Without auto_equip, empty hand fails
	assert_false(world.action(1, "work", {"uid": tree.uid}))

	# With auto_equip, working tree equips flint_axe from inventory
	assert_true(world.action(1, "work", {"uid": tree.uid, "auto_equip": true}))
	assert_eq(_player().inventory.equipment.hand.get("id", ""), "flint_axe")
	assert_eq(int(tree.hits), 1)

	# Working rock swaps flint_pickaxe into hand and returns flint_axe to inventory
	_player().work_cd = 0.0
	assert_true(world.action(1, "work", {"uid": rock.uid, "auto_equip": true}))
	assert_eq(_player().inventory.equipment.hand.get("id", ""), "flint_pickaxe")
	assert_eq(_count_item("flint_axe"), 1)
	assert_eq(int(rock.hits), 1)

	# Beast form still blocks tool usage even with auto_equip
	_player().work_cd = 0.0
	_player().beast_time = 5.0
	assert_false(world.action(1, "work", {"uid": rock.uid, "auto_equip": true}))


func test_player_controls_find_work_candidate_prioritizes_tools() -> void:
	var controls := PlayerControls.new()
	var tree := world.entity("tree", [2.0, 0.0, 0.0])
	tree.merge({"stage": 0, "hits": 0, "depleted": false, "regrow": 0.0})
	world.add_entity("nodes", tree)

	var rock := world.entity("rock", [0.0, 0.0, 2.0])
	rock.merge({"stage": 0, "hits": 0, "depleted": false, "regrow": 0.0})
	world.add_entity("nodes", rock)

	var grass := world.entity("grass", [1.0, 0.0, 0.0])
	grass.merge({"stage": 0, "hits": 0, "depleted": false, "regrow": 0.0})
	world.add_entity("nodes", grass)

	# With no tools, falls back to hand-gatherable grass while reporting nothing missing
	var none_res := controls.find_work_candidate(_player(), world.state)
	assert_eq(int(none_res.node.get("uid", -1)), int(grass.uid))
	assert_eq(none_res.tool, "")

	# With flint_axe in bag, prefers tree over closer grass
	_give("flint_axe", 1)
	var axe_res := controls.find_work_candidate(_player(), world.state)
	assert_eq(int(axe_res.node.get("uid", -1)), int(tree.uid))
	assert_eq(axe_res.tool, "axe")

	# With only a tree nearby and no axe, reports missing_tool == "axe"
	world.remove_entity(grass)
	world.remove_entity(rock)
	_player().inventory = world.inventory({}).to_dict()
	var missing_res := controls.find_work_candidate(_player(), world.state)
	assert_true(missing_res.node.is_empty())
	assert_eq(missing_res.missing_tool, "axe")
