extends GutTest


func _make_world() -> GameWorld:
	var w := GameWorld.new()
	w.initialize(505, {"day_length": 480})
	w.clear_entities()
	w.add_player(1, "Tester")
	return w


func _make_farm(w: GameWorld) -> Dictionary:
	var slots: Array = []
	slots.resize(15)
	for i in 15:
		slots[i] = {}
	var farm: Dictionary = w.entity("farm", [1.0, 0.0, 0.0])
	farm.merge({"health": 200.0, "fuel": 0.0, "ingredients": [], "solvent": "", "remaining": 0.0, "output": "", "pending": "", "slots": slots, "crop": "", "growth": 0.0})
	w.add_entity("structures", farm)
	return farm


func test_water_variants_produce_expected_crops() -> void:
	var w := _make_world()
	var farm := _make_farm(w)
	var p: Dictionary = w.state.players["1"]

	# xich_viem cannot water
	var inv = w.inventory(p)
	inv.add_item("spirit_rice_seed", 1)
	inv.add_item("spirit_water_xich_viem", 1)
	p.inventory = inv.to_dict()
	assert_true(w.action(1, "plant", {"uid": farm.uid, "slot": 0}))
	assert_false(w.action(1, "water", {"uid": farm.uid, "mode": "water"}))
	assert_eq(w.inventory(p).count_item("spirit_water_xich_viem"), 1)

	# huyen_bang on spirit_rice -> frost_rice
	inv = w.inventory(p)
	inv.remove_item("spirit_water_xich_viem", 1)
	inv.add_item("spirit_water_huyen_bang", 1)
	p.inventory = inv.to_dict()
	assert_true(w.action(1, "water", {"uid": farm.uid, "mode": "water"}))
	farm.growth = w.day_length()
	assert_true(w.action(1, "water", {"uid": farm.uid, "mode": "harvest"}))
	assert_eq(w.inventory(p).count_item("frost_rice"), 2)

	# u_minh -> soul_herb
	inv = w.inventory(p)
	inv.add_item("seed", 1)
	inv.add_item("spirit_water_u_minh", 1)
	p.inventory = inv.to_dict()
	var s_idx := -1
	for i in inv.slots.size():
		if inv.slots[i].get("id", "") == "seed":
			s_idx = i
			break
	assert_true(w.action(1, "plant", {"uid": farm.uid, "slot": s_idx}))
	assert_true(w.action(1, "water", {"uid": farm.uid, "mode": "water"}))
	farm.growth = w.day_length()
	assert_true(w.action(1, "water", {"uid": farm.uid, "mode": "harvest"}))
	assert_eq(w.inventory(p).count_item("soul_herb"), 2)
