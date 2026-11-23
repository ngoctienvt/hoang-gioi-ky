extends GutTest


func _make_world() -> GameWorld:
	var w := GameWorld.new()
	w.initialize(101, {"day_length": 480})
	w.clear_entities()
	w.add_player(1, "Tester")
	return w


func test_all_seven_elixir_groups_resolve() -> void:
	var groups := {
		"emergency": ["herb", "herb", "twig", "twig"], # blood_pill
		"env_warm": ["fire_lotus", "herb", "twig", "twig"], # warm_yang_pill
		"env_cool": ["snow_lotus", "herb", "twig", "twig"], # cool_jade_pill
		"env_poison": ["herb", "herb", "mushroom", "twig"], # antidote_pill
		"env_rain": ["water_root", "herb", "herb", "twig"], # water_ward_pill
		"ability_speed": ["volt_moss", "herb", "twig", "twig"], # swift_pill
		"ability_stealth": ["soul_herb", "herb", "twig", "twig"], # conceal_pill
		"boss": ["ghost_general_core", "herb", "twig", "twig"], # pierce_mist_pill
		"awakening": ["monster_core", "herb", "twig", "twig"], # minor_awakening_pill
	}
	for g in groups:
		var res: Dictionary = RecipeDB.match_recipe(groups[g], "alchemy", 0.0)
		assert_ne(str(res.get("result", "waste_pill")), "waste_pill", "Group %s should match an elixir" % g)


func test_solvents_and_tier2_furnace_boost_alchemy_chance() -> void:
	var base: float = RecipeDB.alchemy_chance("warm_yang_pill", 1, "")
	var with_solvent: float = RecipeDB.alchemy_chance("warm_yang_pill", 1, "spirit_water_xich_viem")
	var with_t2: float = RecipeDB.alchemy_chance("warm_yang_pill", 2, "")
	var with_co_van: float = RecipeDB.alchemy_chance("warm_yang_pill", 1, "spirit_water_co_van")
	assert_gt(with_solvent, base)
	assert_almost_eq(with_t2 - base, 0.15, 0.001)
	assert_gt(with_co_van, base)


func test_dan_poison_threshold_triggers_nausea_and_detox_soup_clears() -> void:
	var w := _make_world()
	var p: Dictionary = w.state.players["1"]
	var inv = w.inventory(p)
	inv.add_item("blood_pill", 4)
	inv.add_item("spirit_fruit", 2)
	inv.add_item("detox_soup", 1)
	p.inventory = inv.to_dict()
	for _i in 3:
		assert_true(w.action(1, "use", {"slot": 0}))
	assert_gt(float(p.poison), 50.0)
	assert_true(w.Effects.has(p, "nausea"))
	assert_false(w.action(1, "use", {"slot": 1}))
	w.step(0.1)
	assert_true(w.action(1, "use", {"slot": 2}))
	assert_lt(float(p.poison), 50.0)
