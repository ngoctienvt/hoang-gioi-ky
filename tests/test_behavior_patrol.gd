extends GutTest


func test_construct_beast_patrols_and_chases() -> void:
	var world := GameWorld.new()
	world.initialize(23, {})
	world.clear_entities()
	world.add_player(1, "RuinsExplorer")
	var player: Dictionary = world.state.players["1"]
	player.position = [20.0, 0.0, 0.0]

	var construct := world.entity("construct_beast", [0.0, 0.0, 0.0])
	construct.merge({"health": 160.0, "home": [0.0, 0.0, 0.0], "state": "idle", "behavior_state": "idle", "effects": {}, "cooldown": 0.0, "respawn": 0.0, "stolen": []})
	world.add_entity("creatures", construct)

	for _i in 10:
		world.step(0.5)
	assert_eq(str(construct.state), "wander")
	assert_gt(world.distance(construct.position, [0.0, 0.0, 0.0]), 0.5, "Construct should patrol away from center")

	player.position = [construct.position[0] + 2.0, 0.0, construct.position[2]]
	world.step(0.5)
	assert_eq(str(construct.state), "chase", "Construct should chase player within detect_range")
