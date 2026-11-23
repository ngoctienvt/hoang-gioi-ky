extends GutTest


func test_carrion_crow_eats_meat_drop_and_flees_player() -> void:
	var world := GameWorld.new()
	world.initialize(26, {})
	world.clear_entities()
	world.add_player(1, "Observer")
	var player: Dictionary = world.state.players["1"]
	player.position = [20.0, 0.0, 0.0]

	var crow := world.entity("carrion_crow", [0.0, 0.0, 0.0])
	crow.merge({"health": 40.0, "home": [0.0, 0.0, 0.0], "state": "idle", "behavior_state": "idle", "effects": {}, "cooldown": 0.0, "respawn": 0.0, "stolen": []})
	world.add_entity("creatures", crow)

	world.drop_item("meat", 1, [2.0, 0.0, 0.0])
	assert_eq(world.state.drops.size(), 1)

	for _i in 6:
		world.step(0.5)
	assert_eq(world.state.drops.size(), 0, "Carrion crow should eat dropped meat")

	player.position = [crow.position[0] + 2.0, 0.0, crow.position[2]]
	world.step(0.5)
	assert_eq(str(crow.state), "flee", "Crow should flee when player approaches")
