extends GutTest


func test_migrate_v1_fixture_to_current() -> void:
	var file := FileAccess.open("res://tests/fixtures/save_v1.json", FileAccess.READ)
	assert_not_null(file)
	var parsed = JSON.parse_string(file.get_as_text())
	assert_true(parsed is Dictionary)

	var migrated := SaveManager.migrate_envelope(parsed)
	assert_false(migrated.is_empty())
	assert_eq(float(migrated.options.map_size), 80.0)
	assert_eq(migrated.regions.size(), 6)
	assert_eq(migrated.clock.get("season", ""), "autumn")
	assert_eq(migrated.get("weather", {}).get("kind", ""), "clear")
	var spring_found := false
	for node in migrated.nodes:
		if node.kind == "spring":
			spring_found = true
			assert_eq(node.water_type, "thanh_moc")
	assert_true(spring_found)

	var world := GameWorld.new()
	world.restore(migrated)
	assert_eq(world.index.by_uid.size(), 2)
	assert_eq(world.state.offline_players["Tester"].name, "Tester")
	assert_eq(world.state.offline_players["Tester"].character, "beast_bloodline")


func test_reject_future_save_version() -> void:
	var future := {"version": 99, "state": {"seed": 1}}
	var result := SaveManager.migrate_envelope(future)
	assert_true(result.is_empty())


func test_save_current_version_round_trip_keeps_world_and_steps() -> void:
	# Arrange
	var world := GameWorld.new()
	world.initialize(4242, {})
	world.add_player(1, "Host")
	for i in 50:
		world.step(0.1)
	var before := world.snapshot()
	# Act
	assert_eq(SaveManager.save_world(before, "round_trip_test"), OK)
	var loaded := SaveManager.load_world("round_trip_test")
	var restored := GameWorld.new()
	restored.restore(loaded)
	restored.add_player(1, "Host")
	for i in 20:
		restored.step(0.1)
	# Assert
	assert_eq(SaveManager.last_error, "")
	assert_eq(restored.index.by_uid.size(), world.index.by_uid.size())
	for collection in ["nodes", "structures", "creatures", "drops"]:
		assert_eq(restored.state[collection].size(), before[collection].size(), collection)
	assert_eq(int(restored.state.seed), 4242)
	assert_true(restored.state.players["1"].position is Array)
	_remove_slot("round_trip_test")


func test_migrate_mid_chain_v5_save_and_step() -> void:
	# Arrange: a v5 world with a tempered item stored the old way and a player without a character.
	var world := GameWorld.new()
	world.initialize(99, {})
	world.add_player(1, "Old")
	var data := world.snapshot()
	for key in ["puppets", "karma", "npcs", "forbidden_recipes", "rituals", "secret_realm"]:
		data.erase(key)
	var old: Dictionary = data.players["1"]
	for key in ["character", "ability_cds", "awakening_tier", "skills", "in_secret_realm"]:
		old.erase(key)
	old.stats.erase("base_max_health")
	old.inventory.slots[0] = {"id": "flint_axe", "count": 1, "durability": 50, "vitality_hits": 3}
	# Act
	var migrated := SaveManager.migrate_envelope({"version": 5, "state": data})
	var restored := GameWorld.new()
	restored.restore(migrated)
	restored.add_player(1, "Old")
	for i in 20:
		restored.step(0.1)
	# Assert
	var p: Dictionary = restored.state.players["1"]
	assert_eq(p.character, "beast_bloodline")
	assert_eq(int(p.awakening_tier), 0)
	assert_false(p.in_secret_realm)
	assert_eq(p.inventory.slots[0].get("temper", {}).get("hits", 0), 3)
	assert_false(p.inventory.slots[0].has("vitality_hits"))
	assert_true(restored.state.secret_realm is Dictionary)
	assert_true(restored.state.puppets is Array)


func test_newer_version_save_is_refused_without_backup_fallback() -> void:
	# Arrange: an older backup next to a newer-version main file.
	DirAccess.make_dir_recursive_absolute(SaveManager.SAVE_DIR)
	var base := SaveManager.SAVE_DIR + "future_test.json"
	_write(base, {"version": SaveManager.SAVE_VERSION + 1, "state": {"seed": 1}})
	_write(base + ".bak", {"version": SaveManager.SAVE_VERSION, "state": {"seed": 2}})
	# Act
	var loaded := SaveManager.load_world("future_test")
	# Assert
	assert_true(loaded.is_empty())
	assert_eq(SaveManager.last_error, "SAVE_NEWER_VERSION")
	_remove_slot("future_test")


func _write(path: String, envelope: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(envelope))
	file.close()


func _remove_slot(slot: String) -> void:
	var base := SaveManager.SAVE_DIR + slot + ".json"
	for path in [base, base + ".bak", base + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
