extends GutTest

const Season = preload("res://world/simulation/world_season.gd")
const Helpers = preload("res://tests/structure_test_helpers.gd")


func test_spoilage_ice_cellar_halves_rate_and_spring_soaks_paper_outside_talisman_chest() -> void:
	var world := GameWorld.new()
	world.initialize(12, {"day_length": 480.0})
	world.clear_entities()
	world.add_player(1, "SpoilTester")
	var player: Dictionary = world.state.players["1"]
	player.position = [0.0, 0.0, 0.0]

	var inv = world.inventory(player)
	inv.add_item("meat", 1)
	player.inventory = inv.to_dict()

	# The forest spawn needs an ice block beside the cellar; tier-1 needs a workbench.
	Helpers.place(world, 1, "workbench", [0.0, 0.0, -3.0])
	Helpers.place(world, 1, "ice_structure", [1.5, 0.0, 2.0])
	var cellar := Helpers.place(world, 1, "ice_cellar", [1.5, 0.0, 0.0])
	assert_false(cellar.is_empty(), "ice cellar placed")
	Helpers.store(world, 1, cellar, "meat", 1)
	assert_eq(Helpers.stored_count(cellar, "meat"), 1)

	# Step 480s (half of meat spoil_time 960s), keeping player fed and lit
	for _i in 480:
		player.stats.stamina = 150.0
		player.stats.health = 150.0
		player.stats.dao = 100.0
		world.step(1.0)
	var player_fresh := float(player.inventory.slots[0].get("_f", 1.0))
	var cellar_fresh := float(cellar.slots[0].get("_f", 1.0))
	assert_almost_eq(player_fresh, 0.5, 0.01, "480 s of a 960 s spoil time in the bag")
	assert_almost_eq(cellar_fresh, 0.75, 0.01, "the ice cellar halves the spoil rate")

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

	var chest := Helpers.place(world, 1, "chest", [-1.5, 0.0, 0.0])
	var talisman_chest := Helpers.place(world, 1, "talisman_chest", [-1.5, 0.0, 2.0])
	Helpers.store(world, 1, chest, "talisman_paper", 1)
	Helpers.store(world, 1, talisman_chest, "talisman_paper", 1)

	var inv2 = world.inventory(player)
	inv2.slots[1] = {"id": "talisman_paper", "count": 1}
	player.inventory = inv2.to_dict()

	for _i in 130:
		world.step(1.0)
	assert_true(player.inventory.slots[1].is_empty(), "Talisman paper outside chest in spring rain should soak and break")
	assert_eq(Helpers.stored_count(chest, "talisman_paper"), 0, "a plain chest does not keep paper dry")
	assert_eq(Helpers.stored_count(talisman_chest, "talisman_paper"), 1, "the moisture-proof talisman chest does")
