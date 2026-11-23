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
