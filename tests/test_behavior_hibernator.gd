extends GutTest

const Season = preload("res://world/simulation/world_season.gd")


func _winter_world() -> GameWorld:
	var world := GameWorld.new()
	world.initialize(22, {})
	world.clear_entities()
	# Winter starts after the 20 autumn days; the bear hibernates only then.
	world.state.clock.elapsed = 21.0 * world.day_length() + 1.0
	Season.update_clock(world)
	return world


func test_snow_bear_and_golem_sleep_until_hit_or_loud_noise() -> void:
	var world := _winter_world()
	assert_eq(str(world.state.clock.season), "winter")
	world.add_player(1, "QuietWalker")
	var player: Dictionary = world.state.players["1"]
	player.position = [3.0, 0.0, 0.0]

	var bear := world.entity("snow_bear", [0.0, 0.0, 0.0])
	bear.merge({"health": 220.0, "home": [0.0, 0.0, 0.0], "state": "idle", "behavior_state": "idle", "effects": {}, "cooldown": 0.0, "respawn": 0.0, "stolen": []})
	world.add_entity("creatures", bear)

	var golem := world.entity("stone_golem", [12.0, 0.0, 0.0])
	golem.merge({"health": 240.0, "home": [12.0, 0.0, 0.0], "state": "idle", "behavior_state": "idle", "effects": {}, "cooldown": 0.0, "respawn": 0.0, "stolen": []})
	world.add_entity("creatures", golem)

	for _i in 5:
		world.step(0.5)
	assert_eq(str(bear.state), "sleep", "Snow bear should stay asleep when player walks nearby")
	assert_eq(str(golem.state), "sleep", "Stone golem should stay asleep when player is quiet")

	# Loud noise within 8m wakes snow bear, not golem at 12m
	world.Creatures.notify_noise(world, [2.0, 0.0, 0.0], 8.0)
	world.step(0.5)
	assert_eq(str(bear.state), "chase", "Loud noise should wake snow bear")
	assert_eq(str(golem.state), "sleep")

	# Lightning strike near golem wakes golem
	player.position = [10.0, 0.0, 0.0]
	world.Weather.strike_at(world, [11.0, 0.0, 0.0])
	world.step(0.5)
	assert_eq(str(golem.state), "chase", "Lightning near golem should wake it")


func test_snow_bear_is_awake_outside_winter() -> void:
	# Arrange: autumn, a player walks up to the bear.
	var world := GameWorld.new()
	world.initialize(22, {})
	world.clear_entities()
	world.add_player(1, "Hiker")
	world.state.players["1"].position = [3.0, 0.0, 0.0]
	var bear := world.entity("snow_bear", [0.0, 0.0, 0.0])
	bear.merge({"health": 220.0, "home": [0.0, 0.0, 0.0], "state": "idle", "effects": {}, "cooldown": 0.0, "respawn": 0.0, "stolen": []})
	world.add_entity("creatures", bear)

	# Act
	world.step(0.5)

	# Assert
	assert_eq(str(world.state.clock.season), "autumn")
	assert_eq(str(bear.state), "chase", "outside winter the bear defends its ground")
