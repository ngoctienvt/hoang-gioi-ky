extends GutTest


func _make_world() -> GameWorld:
	var w := GameWorld.new()
	w.initialize(801, {"day_length": 480})
	w.clear_entities()
	w.add_player(1, "Tester")
	w.action(1, "choose_character", {"character": "beast_bloodline"})
	return w


func test_skill_tree_mutual_exclusion_and_tier_gate() -> void:
	var w := _make_world()
	var p: Dictionary = w.state.players["1"]
	p["awakening_tier"] = 1
	p["skill_points"] = 2

	# Tier 2 locked until awakening_tier >= 2
	assert_false(w.action(1, "unlock_skill", {"skill_id": "beast_t2_bloodlust"}))
	# Wrong tree rejected
	assert_false(w.action(1, "unlock_skill", {"skill_id": "devour_t1_gluttony"}))

	# Unlock tier 1 branch A
	assert_true(w.action(1, "unlock_skill", {"skill_id": "beast_t1_ferocity"}))
	assert_eq(int(p.skill_points), 1)
	# Mutually exclusive branch B rejected
	assert_false(w.action(1, "unlock_skill", {"skill_id": "sense_t1_keensense"}))
	assert_eq(int(p.skill_points), 1)


func test_imprint_slots_and_effects() -> void:
	var w := _make_world()
	var p: Dictionary = w.state.players["1"]
	var inv = w.inventory(p)
	inv.add_item("imprint_ghost_general", 1)
	inv.add_item("imprint_frost_wyrm", 1)
	p.inventory = inv.to_dict()

	# Tier 0 has 0 imprint slots
	assert_false(w.action(1, "equip_imprint", {"slot": 0}))

	# Tier 1 allows 1 imprint
	p["awakening_tier"] = 1
	assert_true(w.action(1, "equip_imprint", {"slot": 0}))
	assert_false(w.action(1, "equip_imprint", {"slot": 1}))
	assert_true(w.Skills.has_imprint_effect(p, "no_dark_dao_drain"))

	# Dark night does not drain Dao with Ghost General Imprint
	p.stats["dao"] = 50.0
	w.state.clock["elapsed"] = 450.0 # night
	w.step(1.0)
	assert_gte(float(p.stats.dao), 50.0)

	# Unequip returns item to inventory
	assert_true(w.action(1, "unequip_imprint", {"index": 0}))
	assert_false(w.Skills.has_imprint_effect(p, "no_dark_dao_drain"))
	assert_eq(w.inventory(p).count_item("imprint_ghost_general"), 1)
