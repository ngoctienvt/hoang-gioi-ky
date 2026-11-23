extends GutTest
## Fire, ice blocks, ice cellars and rain on structures built through action("place").

const Helpers = preload("res://tests/structure_test_helpers.gd")
const Weather = preload("res://world/simulation/world_weather.gd")


func _world() -> GameWorld:
	var world := GameWorld.new()
	world.initialize(77, {"day_length": 480.0})
	world.clear_entities()
	world.add_player(1, "Builder")
	world.state.players["1"].position = [0.0, 0.0, 0.0]
	world.state.weather.kind = "clear"
	world.state.weather.timer = 0.0  # next weather roll is half a day away
	# Tier-1 recipes (chest, cellar) need a workbench in reach; this one is out of fire range.
	assert_false(Helpers.place(world, 1, "workbench", [0.0, 0.0, -3.0]).is_empty(), "workbench placed")
	return world


func _keep_alive(world) -> void:
	var stats: Dictionary = world.state.players["1"].stats
	stats.stamina = 150.0
	stats.health = 150.0
	stats.dao = 100.0


func test_fire_burning_down_chest_drops_contents_without_salvage() -> void:
	# Arrange: a chest holding meat and flint, already badly damaged.
	var world := _world()
	var chest := Helpers.place(world, 1, "chest", [2.0, 0.0, 0.0])
	assert_false(chest.is_empty(), "chest placed")
	Helpers.store(world, 1, chest, "flint", 3)
	assert_eq(Helpers.stored_count(chest, "flint"), 3)
	chest.health = 20.0
	var wood_on_ground := Helpers.dropped_count(world, "wood")

	# Act: lightning sets it on fire and it burns down.
	Weather.strike_at(world, chest.position)
	assert_gt(float(chest.get("burning", 0.0)), 0.0, "lightning ignites the chest")
	for _i in 10:
		_keep_alive(world)
		world.step(1.0)

	# Assert: the chest is gone, its contents lie on the ground, the build cost is not refunded.
	assert_true(world.index.find(int(chest.uid)).is_empty(), "chest burnt down")
	assert_eq(Helpers.dropped_count(world, "flint"), 3, "stored items fall out instead of vanishing")
	assert_eq(Helpers.dropped_count(world, "wood"), wood_on_ground, "fire gives no salvage")


func test_fire_going_out_guards_against_reignition() -> void:
	# Arrange
	var world := _world()
	var chest := Helpers.place(world, 1, "chest", [2.0, 0.0, 0.0])
	Weather.strike_at(world, chest.position)

	# Act: let the fire burn out (12 s), then strike again.
	for _i in 14:
		_keep_alive(world)
		world.step(1.0)
	var health_after_fire := float(chest.health)
	Weather.strike_at(world, chest.position)

	# Assert
	assert_eq(float(chest.get("burning", 0.0)), 0.0, "a fire that just went out cannot be relit at once")
	assert_lt(health_after_fire, 200.0, "the first fire did damage")
	assert_false(world.index.find(int(chest.uid)).is_empty(), "one fire does not destroy a healthy chest")


func test_ice_block_placed_by_player_prevents_ignition_and_melts_away() -> void:
	# Arrange
	var world := _world()
	var ice := Helpers.place(world, 1, "ice_structure", [-2.0, 0.0, 0.0])
	var chest := Helpers.place(world, 1, "chest", [2.0, 0.0, 0.0])
	assert_false(ice.is_empty(), "ice block placed")
	assert_gt(float(ice.get("melt", 0.0)), 0.0, "placing an ice block starts its melt timer")

	# Act / Assert: lightning next to the chest does not light it while the ice block stands.
	Weather.strike_at(world, chest.position)
	assert_eq(float(chest.get("burning", 0.0)), 0.0, "ice block nearby keeps the chest from igniting")

	# Act: wait out the melt time.
	for _i in int(ceil(float(ice.melt))) + 5:
		_keep_alive(world)
		world.step(1.0)

	# Assert
	assert_true(world.index.find(int(ice.uid)).is_empty(), "ice block melted away")


func test_ice_cellar_needs_frost_peaks_or_an_ice_block() -> void:
	# Arrange: the spawn area is the forest, not Tuyết Lĩnh.
	var world := _world()
	assert_ne(world.biome_at([3.0, 0.0, 0.0]), "frost_peaks")

	# Act / Assert
	assert_true(Helpers.place(world, 1, "ice_cellar", [3.0, 0.0, 0.0]).is_empty(), "no cellar without cold")
	Helpers.place(world, 1, "ice_structure", [3.0, 0.0, 2.0])
	assert_false(Helpers.place(world, 1, "ice_cellar", [3.0, 0.0, 0.0]).is_empty(), "cellar allowed beside an ice block")


func test_rain_makes_open_fire_burn_fuel_faster() -> void:
	# Arrange: two identical campfires, one stepped in clear weather, one in rain.
	var clear_world := _world()
	var rain_world := _world()
	var clear_fire := Helpers.place(clear_world, 1, "campfire", [2.0, 0.0, 0.0])
	var rain_fire := Helpers.place(rain_world, 1, "campfire", [2.0, 0.0, 0.0])
	assert_false(clear_fire.is_empty(), "campfire placed")
	rain_world.state.weather.kind = "rain"

	# Act
	for _i in 20:
		_keep_alive(clear_world)
		_keep_alive(rain_world)
		clear_world.step(1.0)
		rain_world.step(1.0)

	# Assert: 20 s of fuel used in clear weather, 1.5x that in rain.
	var clear_used := 90.0 - float(clear_fire.fuel)
	var rain_used := 90.0 - float(rain_fire.fuel)
	assert_almost_eq(clear_used, 20.0, 0.01)
	assert_almost_eq(rain_used, 30.0, 0.01)
