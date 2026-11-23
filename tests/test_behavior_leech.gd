extends GutTest


func test_leech_latches_drains_hp_and_detaches_on_hit() -> void:
	var world := GameWorld.new()
	world.initialize(21, {})
	world.clear_entities()
	world.add_player(1, "SwampWalker")
	var player: Dictionary = world.state.players["1"]
	player.position = [0.0, 0.0, 0.0]

	var leech := world.entity("spirit_leech", [0.8, 0.0, 0.0])
	leech.merge({"health": 45.0, "home": [0.0, 0.0, 0.0], "state": "idle", "behavior_state": "idle", "effects": {}, "cooldown": 0.0, "respawn": 0.0, "stolen": []})
	world.add_entity("creatures", leech)

	var hp_before := float(player.stats.health)
	for _i in 6:
		world.step(0.5)
	assert_eq(int(leech.get("attached_peer", -1)), 1, "Leech should latch onto nearby player")
	assert_eq(str(leech.behavior_state), "special")
	assert_lt(float(player.stats.health), hp_before, "Latched leech should drain HP")

	player.attack_cd = 0.0
	assert_true(world.action(1, "attack", {"uid": leech.uid}))
	assert_eq(int(leech.get("attached_peer", -1)), -1, "Attacking leech should detach it")
	assert_eq(str(leech.state), "flee")
