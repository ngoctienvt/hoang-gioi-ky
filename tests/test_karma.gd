extends GutTest


func _make_world(seed_val: int = 707, karma_on: bool = true) -> GameWorld:
	var w := GameWorld.new()
	w.initialize(seed_val, {"day_length": 480, "karma": karma_on})
	w.clear_entities()
	w.add_player(1, "Tester")
	return w


func test_sin_and_fate_actions_decay_and_threshold_trigger() -> void:
	var w := _make_world(707, true)
	var p: Dictionary = w.state.players["1"]
	var rabbit: Dictionary = w.entity("rabbit", [1.5, 0.0, 0.0])
	rabbit.merge({"health": 10.0, "state": "idle", "home": [1.5, 0.0, 0.0], "cooldown": 0.0, "respawn": 0.0, "hit_flash": 0.0, "stolen": [], "effects": {}})
	w.add_entity("creatures", rabbit)
	assert_true(w.action(1, "attack", {"uid": rabbit.uid}))
	assert_gt(float(w.state.karma.sin), 0.0)

	var altar: Dictionary = w.entity("altar", [2.0, 0.0, 0.0])
	w.add_entity("nodes", altar)
	var inv = w.inventory(p)
	inv.add_item("spirit_stone", 2)
	p.inventory = inv.to_dict()
	assert_true(w.action(1, "offer_altar", {"uid": altar.uid, "slot": 0}))
	assert_gt(float(w.state.karma.fate), 0.0)

	# Daily decay -2
	var sin_before: float = float(w.state.karma.sin)
	var fate_before: float = float(w.state.karma.fate)
	w.Karma.on_new_day(w)
	assert_almost_eq(float(w.state.karma.sin), maxf(0.0, sin_before - 2.0), 0.001)
	assert_almost_eq(float(w.state.karma.fate), maxf(0.0, fate_before - 2.0), 0.001)

	# Crossing 30 triggers 1 event and deducts cost
	w.state.karma.sin = 0.0
	w.state.karma_history.clear()
	w.state.karma_cooldowns.clear()
	w.Karma.add_sin(w, 35.0)
	assert_eq(w.state.karma_history.size(), 1)
	assert_lt(float(w.state.karma.sin), 35.0)


func test_both_60_hybrid_and_determinism_and_disable_option() -> void:
	var w1 := _make_world(888, true)
	var w2 := _make_world(888, true)
	w1.state.karma = {"sin": 60.0, "fate": 60.0}
	w2.state.karma = {"sin": 60.0, "fate": 60.0}
	var t1: Array = w1.Karma.check_thresholds(w1)
	var t2: Array = w2.Karma.check_thresholds(w2)
	assert_eq(t1, t2)
	assert_true("both_60_broker" in t1)

	var w_off := _make_world(888, false)
	w_off.state.karma = {"sin": 60.0, "fate": 60.0}
	assert_true(w_off.Karma.check_thresholds(w_off).is_empty())
