extends GutTest

const Replicator = preload("res://world/session/state_replicator.gd")


func test_four_peers_interest_and_600_tick_replication() -> void:
	var world := GameWorld.new()
	world.initialize(777, {})

	var corners := {
		2: [-120.0, 0.0, -120.0],
		3: [120.0, 0.0, -120.0],
		4: [-120.0, 0.0, 120.0],
		5: [120.0, 0.0, 120.0],
	}
	var rep := Replicator.new()
	var clients := {}
	for pid in corners:
		world.add_player(pid, "P%d" % pid)
		world.state.players[str(pid)].position = corners[pid].duplicate()
		var c := Replicator.new()
		c.apply_initial(rep.initial_payload(world, pid))
		clients[pid] = c

	for _tick in 600:
		world.step(0.1)
		var packets := rep.step_host(world, corners.keys())
		for pid in corners:
			var p: Dictionary = packets[pid]
			clients[pid].apply_patch(p.patch)
			if not p.positions.is_empty():
				clients[pid].apply_positions(p.positions)

	# Verify each client has all entities within ENTER_RADIUS chunks and none beyond EXIT_RADIUS chunks
	for pid in corners:
		var pos: Array = world.state.players[str(pid)].position
		var center := WorldEntityIndex.chunk_coords(pos)
		var client_uids: Dictionary = clients[pid].client_entities

		for dx in range(-InterestGrid.ENTER_RADIUS, InterestGrid.ENTER_RADIUS + 1):
			for dz in range(-InterestGrid.ENTER_RADIUS, InterestGrid.ENTER_RADIUS + 1):
				var key := WorldEntityIndex.chunk_key(center.x + dx, center.y + dz)
				for uid in world.index.uids_in_chunk(key):
					assert_true(client_uids.has(uid), "Peer %d missing uid %d in chunk %s" % [pid, uid, key])

		for uid in client_uids:
			var entity: Dictionary = client_uids[uid]
			var ec := WorldEntityIndex.chunk_coords(entity.position)
			var dist := maxi(absi(ec.x - center.x), absi(ec.y - center.y))
			assert_lte(dist, InterestGrid.EXIT_RADIUS, "Peer %d kept out-of-range uid %d" % [pid, uid])
