extends GutTest


func _make_world() -> GameWorld:
	var w := GameWorld.new()
	w.initialize(701, {"day_length": 480})
	w.clear_entities()
	w.add_player(1, "Alice")
	w.add_player(2, "Bob")
	return w


func test_choose_character_once_and_allow_duplicates_and_reconnect() -> void:
	var w := _make_world()
	assert_true(w.action(1, "choose_character", {"character": "devourer"}))
	assert_eq(w.state.players["1"].character, "devourer")
	assert_eq(float(w.state.players["1"].poison_threshold), 150.0)
	# Cannot re-choose once set
	assert_false(w.action(1, "choose_character", {"character": "puppeteer"}))
	assert_eq(w.state.players["1"].character, "devourer")
	# Another player can choose the same character
	assert_true(w.action(2, "choose_character", {"character": "devourer"}))
	assert_eq(w.state.players["2"].character, "devourer")
	# Reconnect by same name keeps chosen character
	w.remove_player(1)
	var saved := w.snapshot()
	var restored := GameWorld.new()
	restored.restore(saved)
	restored.add_player(9, "Alice")
	assert_eq(restored.state.players["9"].character, "devourer")


func test_beast_bloodline_full_moon_doubles_rage_gain() -> void:
	var w1 := _make_world()
	w1.action(1, "choose_character", {"character": "beast_bloodline"})
	w1.state.clock["elapsed"] = 2.0 * 480.0 + 480.0 * 0.9 # day 3 night
	w1.state.players["1"].stats.dao = 20.0
	w1.step(1.0)
	var normal_rage := float(w1.state.players["1"].rage)

	var w2 := _make_world()
	w2.action(1, "choose_character", {"character": "beast_bloodline"})
	w2.state.clock["elapsed"] = 6.0 * 480.0 + 480.0 * 0.9 # day 7 night (full moon)
	w2.state.players["1"].stats.dao = 20.0
	w2.step(1.0)
	var full_moon_rage := float(w2.state.players["1"].rage)
	assert_gt(full_moon_rage, normal_rage * 2.0)
