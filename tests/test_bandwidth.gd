extends GutTest
## Network budget for four peers on the real six-biome map. The world is padded to at least 5,000
## entities with 300+ creatures, players start in the four corners and walk toward the centre (so
## chunks enter and leave interest), and each player has a lit campfire and freshly chopped trees
## nearby so countdown timers are part of the load. Patch sizes are measured with var_to_bytes.

const Replicator = preload("res://world/session/state_replicator.gd")

const MIN_ENTITIES := 5000
const MIN_CREATURES := 300
const SECONDS := 60
const TICK := 0.1
const MAX_AVG_KBPS := 48.0
const MAX_PACKET_KB := 64.0
const MAX_CHUNK_ENTER_KB := 256.0
const CORNERS := {
	2: [-120.0, 0.0, -120.0],
	3: [120.0, 0.0, -120.0],
	4: [-120.0, 0.0, 120.0],
	5: [120.0, 0.0, 120.0],
}


func _padded_world() -> GameWorld:
	var world := GameWorld.new()
	world.initialize(2026, {})
	var half: float = world.map_half() - 4.0
	while world.state.creatures.size() < MIN_CREATURES:
		var pos := [world.rng.randf_range(-half, half), 0.0, world.rng.randf_range(-half, half)]
		var c := world.entity("rabbit", pos)
		c.merge({"health": 20.0, "home": pos.duplicate(), "state": "idle", "cooldown": 0.0, "respawn": 0.0, "stolen": []})
		world.add_entity("creatures", c)
	var kinds := ["tree", "rock", "grass", "berry_bush"]
	while world.index.by_uid.size() < MIN_ENTITIES:
		var pos := [world.rng.randf_range(-half, half), 0.0, world.rng.randf_range(-half, half)]
		var node := world.entity(kinds[world.rng.randi() % kinds.size()], pos)
		node.merge({"stage": 0, "hits": 0, "regrow": 0.0, "age": 0.0, "sapling": false})
		world.add_entity("nodes", node)
	return world


func _add_player_load(world: GameWorld, pid: int) -> void:
	var start: Array = CORNERS[pid]
	var fire := world.entity("campfire", [float(start[0]) + 2.0, 0.0, float(start[2])])
	fire.merge({"health": 200.0, "fuel": 90.0, "ingredients": [], "solvent": "", "remaining": 0.0, "output": "", "pending": "", "slots": [], "crop": "", "growth": 0.0})
	world.add_entity("structures", fire)
	var chopped := 0
	for node in world.index.entities_near(start, 20.0, "nodes"):
		if chopped >= 5:
			break
		node.regrow = 45.0
		node.depleted = true
		world.regrowing_uids[int(node.uid)] = true
		world.touch(int(node.uid))
		chopped += 1


func test_bandwidth_four_peers_full_map_within_budget() -> void:
	# Arrange
	var world := _padded_world()
	var rep := Replicator.new()
	var total_bytes := {}
	var max_initial := 0
	for pid in CORNERS:
		world.add_player(pid, "Peer%d" % pid)
		world.state.players[str(pid)].position = CORNERS[pid].duplicate()
		_add_player_load(world, pid)
	# The host consumes the dirty set every tick; start measuring from a settled world.
	world.index.consume_dirty()
	for pid in CORNERS:
		max_initial = maxi(max_initial, var_to_bytes(rep.initial_payload(world, pid)).size())
		total_bytes[pid] = 0
	var entity_count := world.index.by_uid.size()
	var max_regular := 0
	var max_chunk_enter := 0
	var chunk_enters := 0
	var moved_uids := {}

	# Act: walk toward the centre for the first half, then stand still.
	for tick in SECONDS * 10:
		var chunk_before := {}
		for pid in CORNERS:
			var p: Array = world.state.players[str(pid)].position
			chunk_before[pid] = WorldEntityIndex.chunk_coords(p)
			if tick < SECONDS * 5:
				p[0] = float(p[0]) - signf(CORNERS[pid][0]) * 0.4
				p[2] = float(p[2]) - signf(CORNERS[pid][2]) * 0.4
		world.step(TICK)
		var packets := rep.step_host(world, CORNERS.keys())
		for pid in CORNERS:
			var packet: Dictionary = packets[pid]
			var size := var_to_bytes(packet.patch).size()
			if not packet.positions.is_empty():
				size += var_to_bytes(packet.positions).size()
			var i := 0
			while i < packet.positions.size():
				moved_uids[int(packet.positions[i])] = true
				i += 3
			total_bytes[pid] += size
			if WorldEntityIndex.chunk_coords(world.state.players[str(pid)].position) != chunk_before[pid]:
				chunk_enters += 1
				max_chunk_enter = maxi(max_chunk_enter, size)
			else:
				max_regular = maxi(max_regular, size)

	var max_avg_kbps := 0.0
	for pid in CORNERS:
		max_avg_kbps = maxf(max_avg_kbps, float(total_bytes[pid]) / SECONDS / 1024.0)
	print("[bandwidth] entities=%d creatures=%d moved_uids=%d chunk_enters=%d max_initial_kb=%.2f max_chunk_enter_kb=%.2f max_packet_kb=%.2f max_avg_kbps=%.2f" % [
		entity_count, world.state.creatures.size(), moved_uids.size(), chunk_enters,
		max_initial / 1024.0, max_chunk_enter / 1024.0, max_regular / 1024.0, max_avg_kbps])

	# Assert
	assert_gte(entity_count, MIN_ENTITIES, "World must hold the planned entity load")
	assert_gt(chunk_enters, 0, "Peers must cross chunk borders during the run")
	assert_gte(moved_uids.size(), MIN_CREATURES / 2, "Most creatures must stream positions")
	assert_lte(max_avg_kbps, MAX_AVG_KBPS, "Average download per peer")
	assert_lte(max_regular / 1024.0, MAX_PACKET_KB, "Largest regular packet")
	assert_lte(max_initial / 1024.0, MAX_CHUNK_ENTER_KB, "Join payload")
	assert_lte(max_chunk_enter / 1024.0, MAX_CHUNK_ENTER_KB, "Chunk-enter packet")
