extends GutTest

const Replicator = preload("res://world/session/state_replicator.gd")


func test_bandwidth_six_biome_world_four_players_60s() -> void:
	var world := GameWorld.new()
	world.initialize(2026, {})

	# Ensure at least 300 moving creatures for stress measurement alongside the real 6-biome world
	var current_creatures: int = world.state.creatures.size()
	for i in range(maxi(0, 300 - current_creatures)):
		var rx := world.rng.randf_range(-130.0, 130.0)
		var rz := world.rng.randf_range(-130.0, 130.0)
		var c := world.entity("rabbit", [rx, 0.0, rz])
		c.merge({
			"health": 20.0,
			"home": [rx, 0.0, rz],
			"state": "idle",
			"cooldown": 0.0,
			"respawn": 0.0,
			"stolen": [],
		})
		world.add_entity("creatures", c)

	var corners := {
		2: [-120.0, 0.0, -120.0],
		3: [120.0, 0.0, -120.0],
		4: [-120.0, 0.0, 120.0],
		5: [120.0, 0.0, 120.0],
	}
	var rep := Replicator.new()
	var total_bytes := {}
	var max_packet_bytes := 0
	var max_initial_bytes := 0

	for pid in corners:
		world.add_player(pid, "Peer%d" % pid)
		world.state.players[str(pid)].position = corners[pid].duplicate()
		var init_payload := rep.initial_payload(world, pid)
		var init_size := var_to_bytes(init_payload).size()
		max_initial_bytes = maxi(max_initial_bytes, init_size)
		total_bytes[pid] = 0

	# Simulate 60 seconds at 10 Hz (600 ticks)
	for _tick in 600:
		world.step(0.1)
		var packets := rep.step_host(world, corners.keys())
		for pid in corners:
			var p: Dictionary = packets[pid]
			var sz := var_to_bytes(p.patch).size()
			if not p.positions.is_empty():
				sz += var_to_bytes(p.positions).size()
			total_bytes[pid] += sz
			max_packet_bytes = maxi(max_packet_bytes, sz)

	var max_avg_kbps := 0.0
	for pid in corners:
		var avg_kbps := float(total_bytes[pid]) / 60.0 / 1024.0
		max_avg_kbps = maxf(max_avg_kbps, avg_kbps)

	print("[bandwidth] entities=%d creatures=%d max_initial_kb=%.2f max_packet_kb=%.2f max_avg_kbps=%.2f" % [
		world.index.by_uid.size(),
		world.state.creatures.size(),
		float(max_initial_bytes) / 1024.0,
		float(max_packet_bytes) / 1024.0,
		max_avg_kbps,
	])

	assert_lte(max_avg_kbps, 48.0, "Average download per peer must be <= 48 KB/s")
	assert_lte(float(max_packet_bytes) / 1024.0, 64.0, "Max regular packet must be <= 64 KB")
	assert_lte(float(max_initial_bytes) / 1024.0, 256.0, "Max initial/chunk-enter packet must be <= 256 KB")
