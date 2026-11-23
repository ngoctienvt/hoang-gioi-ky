extends GutTest

const Season = preload("res://world/simulation/world_season.gd")


func test_winter_freezing_campfire_and_fur_coat() -> void:
	var world := GameWorld.new()
	world.initialize(7, {"day_length": 480.0})
	world.clear_entities()
	world.add_player(1, "ColdTester")
	var player: Dictionary = world.state.players["1"]
	player.position = [0.0, 0.0, 0.0]
	player.biome = "bamboo_forest"

	# Force winter
	world.state.clock.elapsed = 20.0 * 480.0 + 10.0
	Season.update_clock(world)
	var hp_start := float(player.stats.health)
	for _i in 35:
		world.step(1.0)
	assert_lt(float(player.stats.temperature), 15.0, "Should freeze outside in Winter without coat")
	assert_lt(float(player.stats.health), hp_start, "Freezing should drain HP")

	# Reset temp and place burning campfire nearby
	player.stats.temperature = 50.0
	player.stats.health = 150.0
	var fire := world.entity("campfire", [1.0, 0.0, 0.0])
	fire.merge({"fuel": 120.0, "health": 200.0, "ingredients": [], "solvent": "", "remaining": 0.0, "output": "", "pending": "", "slots": []})
	world.add_entity("structures", fire)
	for _i in 20:
		world.step(1.0)
	assert_gt(float(player.stats.temperature), 25.0, "Campfire should prevent freezing")

	# Compare fur_coat slowing temperature drop
	world.remove_entity(fire)
	player.stats.temperature = 50.0
	for _i in 10:
		world.step(1.0)
	var bare_temp := float(player.stats.temperature)

	player.stats.temperature = 50.0
	player.inventory.equipment.body = {"id": "fur_coat", "count": 1, "durability": 200}
	for _i in 10:
		world.step(1.0)
	var coat_temp := float(player.stats.temperature)
	assert_gt(coat_temp, bare_temp, "Fur coat should slow temperature drop")


func test_summer_volcano_overheat_huyen_bang_and_cold_attack_cd() -> void:
	var world := GameWorld.new()
	world.initialize(8, {"day_length": 480.0})
	world.clear_entities()
	world.add_player(1, "HeatTester")
	var player: Dictionary = world.state.players["1"]
	# Jump to summer (20 + 15 + 20 = 55 days)
	world.state.clock.elapsed = 55.0 * 480.0 + 10.0
	Season.update_clock(world)
	assert_eq(world.state.clock.season, "summer")

	# Move player to crimson_volcano region center
	for r in world.state.regions:
		if r.biome == "crimson_volcano":
			player.position = r.center.duplicate()
			player.biome = "crimson_volcano"
			break
	var hp_start := float(player.stats.health)
	for _i in 35:
		world.step(1.0)
	assert_gt(float(player.stats.temperature), 85.0, "Volcano in summer should overheat")
	assert_lt(float(player.stats.health), hp_start, "Overheating should drain HP")

	# Drink huyen_bang water cools down
	var inv = world.inventory(player)
	inv.add_item("spirit_water_huyen_bang", 1)
	player.inventory = inv.to_dict()
	assert_true(world.action(1, "use", {"slot": 0}))
	var before_cool := float(player.stats.temperature)
	for _i in 5:
		world.step(1.0)
	assert_lt(float(player.stats.temperature), before_cool, "Huyen Bang water should cool player")

	# Cold attack_cd penalty (< 30 temp)
	player.stats.temperature = 20.0
	var rabbit := world.entity("rabbit", [player.position[0] + 1.0, 0.0, player.position[2]])
	rabbit.merge({"health": 30.0, "home": rabbit.position.duplicate(), "state": "idle", "cooldown": 0.0, "respawn": 0.0, "stolen": [], "effects": {}})
	world.add_entity("creatures", rabbit)
	player.attack_cd = 0.0
	assert_true(world.action(1, "attack", {"uid": rabbit.uid}))
	assert_almost_eq(float(player.attack_cd), 0.65 * 1.25, 0.01)
