extends GutTest


func test_lava_lizard_peaceful_until_hit_then_breathes_fire() -> void:
	var world := GameWorld.new()
	world.initialize(25, {})
	world.clear_entities()
	world.add_player(1, "VolcanoExplorer")
	var player: Dictionary = world.state.players["1"]
	player.position = [2.0, 0.0, 0.0]

	var lizard := world.entity("lava_lizard", [0.0, 0.0, 0.0])
	lizard.merge({"health": 110.0, "home": [0.0, 0.0, 0.0], "state": "idle", "behavior_state": "idle", "effects": {}, "cooldown": 0.0, "respawn": 0.0, "stolen": []})
	world.add_entity("creatures", lizard)

	var hp_before := float(player.stats.health)
	for _i in 4:
		world.step(0.5)
	assert_eq(str(lizard.state), "idle", "Lava lizard should stay peaceful until attacked")
	assert_eq(float(player.stats.health), hp_before)

	player.position = [lizard.position[0] + 1.5, 0.0, lizard.position[2]]
	player.attack_cd = 0.0
	assert_true(world.action(1, "attack", {"uid": lizard.uid}))
	world.step(0.5)
	assert_lt(float(player.stats.health), hp_before, "Provoked lava lizard should deal fire damage")
