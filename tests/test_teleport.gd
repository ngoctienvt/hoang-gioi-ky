extends GutTest


func test_teleport_activation_stone_cost_and_move() -> void:
	var world := GameWorld.new()
	world.initialize(333, {})
	world.add_player(1, "Traveler")
	var player: Dictionary = world.state.players["1"]

	var tps: Array = world.state.teleports
	assert_eq(tps.size(), 6)
	var tp_a: Dictionary = world.index.find(int(tps[0].uid))
	var tp_b: Dictionary = world.index.find(int(tps[1].uid))

	# Dormant cannot be used
	player.position = [tp_a.position[0], 0.0, tp_a.position[2]]
	assert_false(world.action(1, "teleport", {"uid": tp_a.uid, "target_uid": tp_b.uid}))

	# Stepping onto tp_a activates it, but tp_b is still dormant
	world.step(0.1)
	assert_eq(tp_a.state, "active")
	assert_false(world.action(1, "teleport", {"uid": tp_a.uid, "target_uid": tp_b.uid}))

	# Activate tp_b
	player.position = [tp_b.position[0], 0.0, tp_b.position[2]]
	world.step(0.1)
	assert_eq(tp_b.state, "active")

	# Move back to tp_a without spirit_stone -> rejected
	player.position = [tp_a.position[0], 0.0, tp_a.position[2]]
	assert_false(world.action(1, "teleport", {"uid": tp_a.uid, "target_uid": tp_b.uid}))

	# Give spirit_stone -> succeeds and teleports near tp_b
	var inv = world.inventory(player)
	inv.add_item("spirit_stone", 2)
	player.inventory = inv.to_dict()
	assert_true(world.action(1, "teleport", {"uid": tp_a.uid, "target_uid": tp_b.uid}))
	assert_eq(world.inventory(player).count_item("spirit_stone"), 1)
	assert_lt(world.distance(player.position, tp_b.position), 2.5)
