extends GutTest


func _make_world() -> GameWorld:
	var w := GameWorld.new()
	w.initialize(802, {"day_length": 480})
	w.clear_entities()
	w.add_player(1, "Cultivator")
	w.action(1, "choose_character", {"character": "yin_yang"})
	var altar: Dictionary = w.entity("awakening_altar", [2.0, 0.0, 0.0])
	altar.merge({"health": 200.0, "fuel": 0.0, "ingredients": [], "solvent": "", "remaining": 0.0, "output": "", "pending": "", "slots": []})
	w.add_entity("structures", altar)
	return w


func test_awakening_ritual_three_waves_completes_and_grants_tier() -> void:
	var w := _make_world()
	var p: Dictionary = w.state.players["1"]
	var altar: Dictionary = w.state.structures[0]
	var inv = w.inventory(p)
	inv.add_item("minor_awakening_pill", 1)
	inv.add_item("monster_core_low", 3)
	p.inventory = inv.to_dict()

	assert_true(w.action(1, "start_awakening", {"uid": altar.uid}))
	assert_eq(w.state.rituals.size(), 1)
	assert_eq(w.inventory(p).count_item("minor_awakening_pill"), 0)
	assert_gt(w.state.creatures.size(), 0)

	# Keep player healthy & within yin_yang boundary across 3 waves (3 * 12s = 36s)
	for _i in 72:
		p.stats["health"] = 140.0
		p.stats["dao"] = 50.0
		w.step(0.5)

	assert_eq(int(p.awakening_tier), 1)
	assert_eq(int(p.skill_points), 1)
	assert_eq(w.state.rituals.size(), 0)
	assert_gt(float(p.stats.base_max_health), 140.0)


func test_awakening_fails_if_player_leaves_altar() -> void:
	var w := _make_world()
	var p: Dictionary = w.state.players["1"]
	var altar: Dictionary = w.state.structures[0]
	var inv = w.inventory(p)
	inv.add_item("minor_awakening_pill", 1)
	inv.add_item("monster_core_low", 3)
	p.inventory = inv.to_dict()

	assert_true(w.action(1, "start_awakening", {"uid": altar.uid}))
	p.position = [25.0, 0.0, 0.0]
	w.step(0.5)
	assert_eq(w.state.rituals.size(), 0)
	assert_eq(int(p.awakening_tier), 0)
