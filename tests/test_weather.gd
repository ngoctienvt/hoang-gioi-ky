extends GutTest

const Weather = preload("res://world/simulation/world_weather.gd")
const Season = preload("res://world/simulation/world_season.gd")


func test_lightning_warning_and_rod_absorption() -> void:
	var world := GameWorld.new()
	world.initialize(10, {"day_length": 480.0})
	world.clear_entities()
	world.add_player(1, "StormTester")
	var player: Dictionary = world.state.players["1"]
	player.position = [0.0, 0.0, 0.0]

	# Schedule lightning without rod -> warning first, then strike hurts player
	Weather.schedule_lightning(world, [0.5, 0.0, 0.0])
	assert_eq(world.state.weather.warnings.size(), 1)
	var hp_before := float(player.stats.health)
	world.step(1.0)
	assert_eq(float(player.stats.health), hp_before, "Should not strike during 2s warning")
	assert_eq(world.state.weather.warnings.size(), 1)
	world.step(1.0)
	assert_eq(world.state.weather.warnings.size(), 0)
	assert_lt(float(player.stats.health), hp_before, "Strike after warning should hurt nearby player")

	# Place lightning rod within 10m -> absorbs strike and yields charged_thunder_crystal
	var rod := world.entity("lightning_rod", [4.0, 0.0, 0.0])
	rod.merge({"health": 200.0, "fuel": 0.0, "ingredients": [], "solvent": "", "remaining": 0.0, "output": "", "pending": "", "slots": [], "charges": 0})
	world.add_entity("structures", rod)
	var hp_protected := float(player.stats.health)
	Weather.schedule_lightning(world, [0.5, 0.0, 0.0])
	world.step(1.0)
	world.step(1.0)
	assert_eq(float(player.stats.health), hp_protected, "Lightning rod should absorb strike")
	assert_eq(int(rod.charges), 1)
	player.position = [3.0, 0.0, 0.0]
	assert_true(world.action(1, "take", {"uid": rod.uid}))
	assert_eq(int(rod.charges), 0)
	assert_eq(world.inventory(player).count_item("charged_thunder_crystal"), 1)


func test_rain_dao_drain_waterproof_and_frozen_winter_spring() -> void:
	var world := GameWorld.new()
	world.initialize(11, {"day_length": 480.0})
	world.clear_entities()
	world.add_player(1, "RainTester")
	var player: Dictionary = world.state.players["1"]
	player.position = [0.0, 0.0, 0.0]
	player.biome = "bamboo_forest"
	world.state.weather.kind = "rain"

	# Bare player dao drain
	player.stats.dao = 100.0
	world.step(1.0)
	var bare_dao := float(player.stats.dao)
	assert_lt(bare_dao, 100.0)

	# With straw_hat (waterproof 0.75) dao drains much less
	player.stats.dao = 100.0
	player.inventory.equipment.head = {"id": "straw_hat", "count": 1, "durability": 180}
	world.step(1.0)
	assert_gt(float(player.stats.dao), bare_dao)

	# Frozen spring in winter blocks fill until 3 pickaxe hits
	world.state.clock.elapsed = 20.0 * 480.0 + 10.0
	Season.update_clock(world)
	var spring := world.entity("spring", [1.5, 0.0, 0.0])
	spring.merge({"water_type": "thanh_moc", "biome": "bamboo_forest"})
	world.add_entity("nodes", spring)
	world.step(0.1)
	assert_true(spring.get("frozen", false), "Non-volcano spring should freeze in winter")

	var inv = world.inventory(player)
	inv.add_item("water_bottle", 1)
	inv.equipment.hand = {"id": "flint_pickaxe", "count": 1, "durability": 60}
	player.inventory = inv.to_dict()
	assert_false(world.action(1, "water", {"uid": spring.uid, "mode": "fill"}))
	for _i in 3:
		player.work_cd = 0.0
		assert_true(world.action(1, "work", {"uid": spring.uid}))
	assert_false(spring.get("frozen", false))
	assert_true(world.action(1, "water", {"uid": spring.uid, "mode": "fill"}))
