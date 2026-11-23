extends GutTest
## Timed player effects expire and the environment-resistance pills and ward talisman really protect.

const Weather = preload("res://world/simulation/world_weather.gd")
const Season = preload("res://world/simulation/world_season.gd")


func _world() -> GameWorld:
	var world := GameWorld.new()
	world.initialize(91, {"day_length": 480.0})
	world.clear_entities()
	world.add_player(1, "Tester")
	world.state.players["1"].position = [0.0, 0.0, 0.0]
	world.state.weather.kind = "clear"
	world.state.weather.timer = 0.0
	return world


func _steps(world, seconds: int) -> void:
	for _i in seconds:
		world.step(1.0)


func test_effects_stealth_expires_after_its_duration() -> void:
	# Arrange
	var world := _world()
	var player: Dictionary = world.state.players["1"]
	world.Effects.apply(world, player, "stealth", 1.0, 1.0)
	assert_true(world.Effects.has(player, "stealth"))

	# Act
	_steps(world, 2)

	# Assert
	assert_false(world.Effects.has(player, "stealth"), "stealth wears off")


func test_effects_temp_lock_holds_body_temperature_in_the_cold() -> void:
	# Arrange: a player frozen solid in winter-level cold with Ôn Dương Đan active.
	var world := _world()
	var player: Dictionary = world.state.players["1"]
	player.stats.temperature = 50.0
	world.Effects.apply_item(world, player, ItemDB.get_item("warm_yang_pill"))
	var unlocked := _world()
	unlocked.state.players["1"].stats.temperature = 50.0
	for w in [world, unlocked]:
		w.state.clock.elapsed = 22.0 * 480.0  # early winter
		Season.update_clock(w)

	# Act
	for _i in 30:
		for w in [world, unlocked]:
			w.state.players["1"].stats.stamina = 150.0
			w.step(1.0)

	# Assert
	assert_lt(float(unlocked.state.players["1"].stats.temperature), 49.0, "without the pill the body cools")
	assert_almost_eq(float(player.stats.temperature), 50.0, 0.01, "temperature pinned at 50")


func test_effects_lightning_ward_blocks_a_strike() -> void:
	# Arrange
	var world := _world()
	var player: Dictionary = world.state.players["1"]
	world.Effects.apply(world, player, "lightning_immune", 1.0, 30.0)
	var hp := float(player.stats.health)

	# Act
	Weather.strike_at(world, player.position)

	# Assert
	assert_eq(float(player.stats.health), hp, "ward absorbs the bolt")


func test_effects_water_ward_stops_rain_dao_drain() -> void:
	# Arrange: same rain, one player warded.
	var warded := _world()
	var bare := _world()
	for w in [warded, bare]:
		w.state.weather.kind = "rain"
		w.state.players["1"].stats.dao = 80.0
	warded.Effects.apply(warded, warded.state.players["1"], "rain_immune", 1.0, 480.0)
	var mods_warded := {"dao": 0.0}
	var mods_bare := {"dao": 0.0}

	# Act
	Weather.apply_player_weather(warded, warded.state.players["1"], 1.0, mods_warded)
	Weather.apply_player_weather(bare, bare.state.players["1"], 1.0, mods_bare)

	# Assert
	assert_lt(float(mods_bare.dao), 0.0, "rain drains an unwarded player")
	assert_eq(float(mods_warded.dao), 0.0, "Tị Thủy Đan keeps the rain off")


func test_effects_nausea_halves_healing() -> void:
	# Arrange
	var sick := _world()
	var well := _world()
	for w in [sick, well]:
		var p: Dictionary = w.state.players["1"]
		p.stats.health = 50.0
		w.Effects.apply(w, p, "regen", 4.0, 30.0)
	sick.Effects.apply(sick, sick.state.players["1"], "nausea", 1.0, 30.0)

	# Act
	for _i in 5:
		for w in [sick, well]:
			w.state.players["1"].stats.stamina = 150.0
			w.step(1.0)

	# Assert
	var sick_gain := float(sick.state.players["1"].stats.health) - 50.0
	var well_gain := float(well.state.players["1"].stats.health) - 50.0
	assert_gt(well_gain, 0.0)
	assert_almost_eq(sick_gain, well_gain * 0.5, 0.5, "nausea halves recovery")
