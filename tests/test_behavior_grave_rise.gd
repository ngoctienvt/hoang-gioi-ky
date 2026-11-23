extends GutTest


func test_jiangshi_sleeps_by_day_and_rises_at_night() -> void:
	var world := GameWorld.new()
	world.initialize(24, {"day_length": 480.0})
	world.clear_entities()
	world.add_player(1, "GraveVisitor")
	var player: Dictionary = world.state.players["1"]
	player.position = [3.0, 0.0, 0.0]

	var js := world.entity("jiangshi", [0.0, 0.0, 0.0])
	js.merge({"health": 120.0, "home": [0.0, 0.0, 0.0], "state": "idle", "behavior_state": "idle", "effects": {}, "cooldown": 0.0, "respawn": 0.0, "stolen": []})
	world.add_entity("creatures", js)

	# Day time -> sleeps
	world.step(0.5)
	assert_eq(str(js.state), "sleep")

	# Night time (90% of day) -> rises and chases
	world.state.clock.elapsed = 440.0
	world.step(0.5)
	assert_eq(str(js.state), "chase")
