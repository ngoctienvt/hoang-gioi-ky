extends GutTest


func test_ice_wolf_hunts_prey_and_effects_work() -> void:
	var world := GameWorld.new()
	world.initialize(27, {})
	world.clear_entities()
	world.add_player(1, "Watcher")
	var player: Dictionary = world.state.players["1"]
	player.position = [20.0, 0.0, 0.0]

	var wolf := world.entity("ice_wolf", [0.0, 0.0, 0.0])
	wolf.merge({"health": 120.0, "home": [0.0, 0.0, 0.0], "state": "idle", "behavior_state": "idle", "effects": {}, "cooldown": 0.0, "respawn": 0.0, "stolen": []})
	world.add_entity("creatures", wolf)

	var prey := world.entity("thick_fur_beast", [2.0, 0.0, 0.0])
	prey.merge({"health": 75.0, "home": [2.0, 0.0, 0.0], "state": "idle", "behavior_state": "idle", "effects": {}, "cooldown": 0.0, "respawn": 0.0, "stolen": []})
	world.add_entity("creatures", prey)

	for _i in 20:
		world.step(0.1)
	assert_eq(str(wolf.state), "chase")
	assert_lt(float(prey.health), 75.0, "Ice wolf should hunt thick_fur_beast")

	# Test burn, slow, stun effects on wolf
	var hp_before := float(wolf.health)
	world.Creatures.apply_effect(world, wolf, "burn", 3.0)
	world.Creatures.apply_effect(world, wolf, "stun", 1.0)
	world.step(0.5)
	assert_lt(float(wolf.health), hp_before, "Burn effect should damage creature")
	assert_eq(str(wolf.state), "idle", "Stun should freeze creature AI")
