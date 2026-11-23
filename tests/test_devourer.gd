extends GutTest


func _make_world() -> GameWorld:
	var w := GameWorld.new()
	w.initialize(702, {"day_length": 480})
	w.clear_entities()
	w.add_player(1, "Devourer")
	w.action(1, "choose_character", {"character": "devourer"})
	return w


func test_devour_monster_core_and_herbs_effects_and_threshold() -> void:
	var w := _make_world()
	var p: Dictionary = w.state.players["1"]
	assert_eq(float(p.poison_threshold), 150.0)
	p.stats.health = 80.0
	var inv = w.inventory(p)
	inv.add_item("monster_core_low", 6)
	p.inventory = inv.to_dict()
	assert_true(w.action(1, "ability", {"name": "devour", "slot": 0}))
	assert_gt(float(p.stats.health), 80.0)
	assert_true(w.Effects.has(p, "damage_boost"))
	assert_eq(float(p.poison), 20.0)
	# Threshold is 150, so 120 poison does not trigger nausea
	for _i in 5:
		p.ability_cds["devour"] = 0.0
		assert_true(w.action(1, "ability", {"name": "devour", "slot": 0}))
	assert_eq(float(p.poison), 120.0)
	assert_false(w.Effects.has(p, "nausea"))
	# 160 poison exceeds 150 and triggers nausea
	inv = w.inventory(p)
	inv.add_item("monster_core_low", 2)
	p.inventory = inv.to_dict()
	for _i in 2:
		p.ability_cds["devour"] = 0.0
		assert_true(w.action(1, "ability", {"name": "devour", "slot": 0}))
	assert_gt(float(p.poison), 150.0)
	assert_true(w.Effects.has(p, "nausea"))


func test_devour_fire_then_ice_within_60s_causes_conflict_backlash() -> void:
	var w := _make_world()
	var p: Dictionary = w.state.players["1"]
	var inv = w.inventory(p)
	inv.add_item("fire_lotus", 1)
	inv.add_item("snow_lotus", 1)
	p.inventory = inv.to_dict()
	assert_true(w.action(1, "ability", {"name": "devour", "slot": 0}))
	assert_true(w.Effects.has(p, "cold_resist"))
	var hp_before := float(p.stats.health)
	var dao_before := float(p.stats.dao)
	p.ability_cds["devour"] = 0.0
	assert_true(w.action(1, "ability", {"name": "devour", "slot": 1}))
	assert_lt(float(p.stats.health), hp_before)
	assert_lt(float(p.stats.dao), dao_before)
