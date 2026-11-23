extends GutTest


func _make_world() -> GameWorld:
	var w := GameWorld.new()
	w.initialize(202, {"day_length": 480})
	w.clear_entities()
	w.add_player(1, "Tester")
	return w


func test_craft_talisman_requires_desk_and_cinnabar() -> void:
	var w := _make_world()
	var p: Dictionary = w.state.players["1"]
	var inv = w.inventory(p)
	inv.add_item("talisman_paper", 2)
	inv.add_item("grass", 4)
	p.inventory = inv.to_dict()
	assert_false(w.action(1, "craft", {"recipe": "bind_talisman"}))
	var desk: Dictionary = w.entity("talisman_desk", [1.0, 0.0, 0.0])
	desk.merge({"health": 200.0, "fuel": 0.0, "ingredients": [], "solvent": "", "remaining": 0.0, "output": "", "pending": "", "slots": []})
	w.add_entity("structures", desk)
	assert_false(w.action(1, "craft", {"recipe": "bind_talisman"}))
	inv = w.inventory(p)
	inv.add_item("cinnabar", 1)
	p.inventory = inv.to_dict()
	assert_true(w.action(1, "craft", {"recipe": "bind_talisman"}))
	assert_eq(w.inventory(p).count_item("bind_talisman"), 2)


func test_bind_and_frost_talisman_affect_creature() -> void:
	var w := _make_world()
	var p: Dictionary = w.state.players["1"]
	var inv = w.inventory(p)
	inv.add_item("bind_talisman", 1)
	inv.add_item("frost_talisman", 1)
	p.inventory = inv.to_dict()
	var wolf: Dictionary = w.entity("wolf", [3.0, 0.0, 0.0])
	wolf.merge({"health": 100.0, "state": "chase", "home": [3.0, 0.0, 0.0], "cooldown": 0.0, "respawn": 0.0, "hit_flash": 0.0, "stolen": [], "effects": {}, "channeling": 2.0})
	w.add_entity("creatures", wolf)
	assert_true(w.action(1, "throw_talisman", {"slot": 0, "uid": wolf.uid}))
	assert_true(w.Effects.has(wolf, "stun"))
	var pos_before: Array = wolf.position.duplicate()
	w.Creatures.step(w, 0.5)
	assert_eq(wolf.position, pos_before)
	assert_true(w.action(1, "throw_talisman", {"slot": 1, "uid": wolf.uid}))
	assert_true(w.Effects.has(wolf, "slow"))
	assert_eq(float(wolf.channeling), 0.0)


func test_talisman_chest_keeps_paper_dry() -> void:
	var w := _make_world()
	var p: Dictionary = w.state.players["1"]
	var inv = w.inventory(p)
	inv.add_item("bind_talisman", 2)
	p.inventory = inv.to_dict()
	var tchest: Dictionary = w.entity("talisman_chest", [1.0, 0.0, 0.0])
	var slots: Array = []
	slots.resize(15)
	for i in 15:
		slots[i] = {}
	tchest.merge({"health": 200.0, "fuel": 0.0, "ingredients": [], "solvent": "", "remaining": 0.0, "output": "", "pending": "", "slots": slots, "crop": "", "growth": 0.0, "moisture_proof": true})
	w.add_entity("structures", tchest)
	assert_true(w.action(1, "chest_put", {"uid": tchest.uid, "slot": 0}))
	w.Talismans.apply_moisture(w, 10.0, 0.05)
	assert_gt(float(p.inventory.slots[0].get("soak", 0.0)), 0.0)
	assert_eq(float(tchest.slots[0].get("soak", 0.0)), 0.0)
