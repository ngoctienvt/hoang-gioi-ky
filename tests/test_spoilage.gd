extends GutTest

const Season = preload("res://world/simulation/world_season.gd")


func test_spoilage_ice_cellar_and_spring_paper_soak() -> void:
	var world := GameWorld.new()
	world.initialize(12, {"day_length": 480.0})
	world.clear_entities()
	world.add_player(1, "SpoilTester")
	var player: Dictionary = world.state.players["1"]
	player.position = [0.0, 0.0, 0.0]

	var inv = world.inventory(player)
	inv.add_item("meat", 1)
	player.inventory = inv.to_dict()

	var cellar := world.entity("ice_cellar", [1.5, 0.0, 0.0])
	cellar.merge({"health": 200.0, "fuel": 0.0, "ingredients": [], "solvent": "", "remaining": 0.0, "output": "", "pending": "", "slots": []})
	cellar.slots.resize(15)
	for i in 15:
		cellar.slots[i] = {}
	cellar.slots[0] = {"id": "meat", "count": 1, "freshness": 1.0}
	world.add_entity("structures", cellar)

	# Step 480s (half of meat spoil_time 960s), keeping player fed and lit
	for _i in 480:
		player.stats.stamina = 150.0
		player.stats.health = 150.0
		player.stats.dao = 100.0
		world.step(1.0)
	var player_fresh := float(player.inventory.slots[0].get("freshness", 1.0))
	var cellar_fresh := float(cellar.slots[0].get("freshness", 1.0))
	assert_lt(player_fresh, 0.6)
	assert_gt(cellar_fresh, player_fresh, "Ice cellar should slow spoilage by 50%")

	# Step another 500s -> player meat spoils to spoiled_food
	for _i in 500:
		player.stats.stamina = 150.0
		player.stats.health = 150.0
		player.stats.dao = 100.0
		world.step(1.0)
	assert_eq(player.inventory.slots[0].get("id", ""), "spoiled_food")

	# Spring paper soak: outside chest gets destroyed, inside chest stays safe
	world.state.clock.elapsed = 35.0 * 480.0 + 10.0
	Season.update_clock(world)
	assert_eq(world.state.clock.season, "spring")
	world.state.weather.kind = "rain"

	var chest := world.entity("chest", [-1.5, 0.0, 0.0])
	chest.merge({"health": 200.0, "fuel": 0.0, "ingredients": [], "solvent": "", "remaining": 0.0, "output": "", "pending": "", "slots": []})
	chest.slots.resize(15)
	for i in 15:
		chest.slots[i] = {}
	chest.slots[0] = {"id": "talisman_paper", "count": 1}
	world.add_entity("structures", chest)

	var inv2 = world.inventory(player)
	inv2.slots[1] = {"id": "talisman_paper", "count": 1}
	player.inventory = inv2.to_dict()

	for _i in 130:
		world.step(1.0)
	assert_true(player.inventory.slots[1].is_empty(), "Talisman paper outside chest in spring rain should soak and break")
	assert_eq(chest.slots[0].get("id", ""), "talisman_paper", "Talisman paper inside chest should stay dry")
