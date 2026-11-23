extends GutTest


func _make_world() -> GameWorld:
	var w := GameWorld.new()
	w.initialize(606, {"day_length": 480})
	w.clear_entities()
	w.add_player(1, "Owner")
	w.add_player(2, "Other")
	return w


func test_heart_demon_spawn_banish_and_peer_isolation() -> void:
	var w := _make_world()
	var p1: Dictionary = w.state.players["1"]
	p1.stats.dao = 25.0
	w.HeartDemon.step(w, 0.1)
	assert_eq(w.HeartDemon._owned_demons(w, 1).size(), 1)
	p1.stats.dao = 10.0
	w.HeartDemon.step(w, 0.1)
	assert_eq(w.HeartDemon._owned_demons(w, 1).size(), 2)

	# Replicator hides owner 1's heart_demon from peer 2
	var rep := StateReplicator.new()
	var init1 := rep.initial_payload(w, 1)
	var init2 := rep.initial_payload(w, 2)
	var p1_has := false
	for e in init1.get("upsert", []):
		if e.kind == "heart_demon":
			p1_has = true
	var p2_has := false
	for e in init2.get("upsert", []):
		if e.kind == "heart_demon":
			p2_has = true
	assert_true(p1_has)
	assert_false(p2_has)

	# Calm pill banishes heart demons
	var inv = w.inventory(p1)
	inv.add_item("calm_pill", 1)
	p1.inventory = inv.to_dict()
	assert_true(w.action(1, "use", {"slot": 0}))
	assert_eq(w.HeartDemon._owned_demons(w, 1).size(), 0)

	# Raising dao above 40 dissipates
	p1.stats.dao = 25.0
	w.HeartDemon.step(w, 0.1)
	assert_eq(w.HeartDemon._owned_demons(w, 1).size(), 1)
	p1.stats.dao = 45.0
	w.HeartDemon.step(w, 0.1)
	assert_eq(w.HeartDemon._owned_demons(w, 1).size(), 0)
