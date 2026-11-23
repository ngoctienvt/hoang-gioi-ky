extends GutTest
## Host world vs four client mirrors fed only by per-peer patches. Peers walk across the map so
## chunk enter/exit, entities leaving interest and removals are all exercised.

const Replicator = preload("res://world/session/state_replicator.gd")
const Mirror = preload("res://world/session/replica_mirror.gd")

const STARTS := {
	2: [-120.0, 0.0, -120.0],
	3: [120.0, 0.0, -120.0],
	4: [-120.0, 0.0, 120.0],
	5: [120.0, 0.0, 120.0],
}

var world: GameWorld
var rep: StateReplicator
var mirrors: Dictionary


func before_each() -> void:
	world = GameWorld.new()
	world.initialize(777, {})
	rep = Replicator.new()
	mirrors = {}
	for pid in STARTS:
		world.add_player(pid, "P%d" % pid)
		world.state.players[str(pid)].position = STARTS[pid].duplicate()
		var mirror := Mirror.new()
		mirror.apply_initial(rep.initial_payload(world, pid))
		mirrors[pid] = mirror


func _tick(walk: bool) -> void:
	if walk:
		# Each peer walks diagonally toward the opposite corner, ~4 m/s, crossing many chunks.
		for pid in STARTS:
			var start: Array = STARTS[pid]
			var p: Array = world.state.players[str(pid)].position
			p[0] = float(p[0]) - signf(start[0]) * 0.4
			p[2] = float(p[2]) - signf(start[2]) * 0.4
	world.step(0.1)
	var packets := rep.step_host(world, STARTS.keys())
	for pid in STARTS:
		mirrors[pid].apply_patch(packets[pid].patch)
		mirrors[pid].apply_positions(packets[pid].positions)


func test_mirrors_hold_exactly_the_entities_in_interest() -> void:
	for tick in 600:
		_tick(true)
		if tick % 100 == 99:
			for pid in STARTS:
				_assert_membership(pid)


func test_mirror_entities_match_host_fields() -> void:
	for tick in 600:
		_tick(tick < 300)
	for pid in STARTS:
		var mismatches := _field_mismatches(pid)
		assert_eq(mismatches, [], "Peer %d diverged from host" % pid)


func test_other_players_carry_character_and_equipment() -> void:
	world.state.players["3"].character = "yin_yang"
	world.state.players["3"].inventory.equipment["hand"] = {"id": "torch", "count": 1, "durability": 10}
	_tick(false)
	var seen: Dictionary = mirrors[2].state.players["3"]
	assert_eq(seen.get("character"), "yin_yang")
	assert_eq(seen.inventory.equipment.hand.id, "torch")
	assert_false(seen.has("stats"), "Teammates must not receive private stats")


func test_player_leave_and_erased_fields_reach_mirrors() -> void:
	world.state.players["3"]["test_marker"] = "set"
	_tick(false)
	assert_eq(mirrors[3].state.players["3"].get("test_marker", ""), "set")
	world.state.players["3"].erase("test_marker")
	world.remove_player(5)
	_tick(false)
	assert_false(mirrors[3].state.players["3"].has("test_marker"), "Erased field must be erased on the mirror")
	assert_false(mirrors[2].state.players.has("5"), "Departed player must leave every mirror")


func test_clock_reaches_mirror_as_field_delta() -> void:
	for i in 20:
		_tick(false)
	for key in world.state.clock:
		assert_eq(str(mirrors[4].state.clock.get(key)), str(world.state.clock[key]), "clock.%s" % key)


func _assert_membership(pid: int) -> void:
	var center := WorldEntityIndex.chunk_coords(world.state.players[str(pid)].position)
	var held: Dictionary = mirrors[pid].entities
	var expected: Dictionary = {}
	for uid in world.index.by_uid:
		var ec := WorldEntityIndex.chunk_coords(world.index.by_uid[uid].position)
		var dist := maxi(absi(ec.x - center.x), absi(ec.y - center.y))
		if dist <= InterestGrid.ENTER_RADIUS:
			assert_true(held.has(uid), "Peer %d missing near uid %d" % [pid, uid])
		if rep.interest.sees_chunk(pid, world.index.entity_chunk[uid]) and StateReplicator._visible_to_peer(world.index.by_uid[uid], pid):
			expected[uid] = true
	for uid in held:
		assert_true(expected.has(uid), "Peer %d holds uid %d outside its interest" % [pid, uid])
	assert_eq(held.size(), expected.size(), "Peer %d entity count" % pid)


func _field_mismatches(pid: int) -> Array:
	var out: Array = []
	for uid in mirrors[pid].entities:
		var host: Dictionary = world.index.find(uid)
		if host.is_empty():
			out.append("%d removed on host" % uid)
			continue
		var expected := StateReplicator.public_entity(host, world.index.collection_of[uid])
		var got: Dictionary = mirrors[pid].entities[uid]
		for key in expected:
			if key == "position":
				var d := Vector2(float(expected.position[0]) - float(got.position[0]), float(expected.position[2]) - float(got.position[2])).length()
				if d > 0.25:
					out.append("%d %s position off %.2f" % [uid, expected.kind, d])
			elif key in StateReplicator.COARSE_TIMERS and got.has(key) and absf(float(got[key]) - float(expected[key])) <= 1.0:
				continue
			elif not got.has(key) or str(got[key]) != str(expected[key]):
				out.append("%d %s.%s host=%s client=%s" % [uid, expected.kind, key, str(expected[key]), str(got.get(key))])
	return out
