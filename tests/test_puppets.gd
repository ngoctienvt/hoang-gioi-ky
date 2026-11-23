extends GutTest


func _make_world() -> GameWorld:
	var w := GameWorld.new()
	w.initialize(303, {"day_length": 480})
	w.clear_entities()
	w.add_player(1, "Tester")
	return w


func _empty_slots() -> Array:
	var slots: Array = []
	slots.resize(15)
	for i in 15:
		slots[i] = {}
	return slots


func test_haul_puppet_picks_drop_and_stores_in_chest() -> void:
	var w := _make_world()
	var chest: Dictionary = w.entity("chest", [2.0, 0.0, 0.0])
	chest.merge({"health": 200.0, "fuel": 0.0, "ingredients": [], "solvent": "", "remaining": 0.0, "output": "", "pending": "", "slots": _empty_slots(), "crop": "", "growth": 0.0})
	w.add_entity("structures", chest)
	w.drop_item("wood", 3, [4.0, 0.0, 0.0])
	var puppet: Dictionary = w.Puppets.spawn_puppet(w, "puppet_haul", [3.0, 0.0, 0.0], 1)
	for _i in 40:
		w.Puppets.step(w, 0.25)
	assert_eq(w.state.drops.size(), 0)
	var inv = w.inventory({"inventory": {"slots": chest.slots, "equipment": {}}})
	assert_eq(inv.count_item("wood"), 3)
	assert_true(puppet.carrying.is_empty())


func test_chop_puppet_respects_stake_radius_and_fuel() -> void:
	var w := _make_world()
	var stake: Dictionary = w.entity("stake", [0.0, 0.0, 0.0])
	stake.merge({"health": 200.0, "fuel": 0.0, "ingredients": [], "solvent": "", "remaining": 0.0, "output": "", "pending": "", "slots": _empty_slots(), "crop": "", "growth": 0.0, "radius": 8.0})
	w.add_entity("structures", stake)
	var inside_tree: Dictionary = w.entity("tree", [3.0, 0.0, 0.0])
	inside_tree.merge({"stage": 0, "hits": 0, "regrow": 0.0, "sapling": false})
	w.add_entity("nodes", inside_tree)
	var outside_tree: Dictionary = w.entity("tree", [15.0, 0.0, 0.0])
	outside_tree.merge({"stage": 0, "hits": 0, "regrow": 0.0, "sapling": false})
	w.add_entity("nodes", outside_tree)
	var puppet: Dictionary = w.Puppets.spawn_puppet(w, "puppet_chop", [1.0, 0.0, 0.0], 1)
	for _i in 80:
		w.Puppets.step(w, 0.25)
	assert_true(inside_tree.get("depleted", false) or int(inside_tree.get("stage", 0)) > 0)
	assert_eq(int(outside_tree.get("hits", 0)), 0)
	assert_eq(int(outside_tree.get("stage", 0)), 0)
	puppet.fuel = 0.05
	w.Puppets.step(w, 0.1)
	assert_eq(puppet.state, "out_of_fuel")
