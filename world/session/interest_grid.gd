class_name InterestGrid
extends RefCounted
## Per-peer area of interest: the set of chunks a peer can see and the entity uids it currently holds.
## Chunks within ENTER_RADIUS of the player are added; chunks are dropped only beyond EXIT_RADIUS,
## so a player walking along a chunk border does not make entities flicker in and out.

const ENTER_RADIUS := 2
const EXIT_RADIUS := 3

var peer_chunks: Dictionary = {}  # peer_id -> {chunk_key: true}
var peer_uids: Dictionary = {}  # peer_id -> {uid: true}, exactly what the peer's mirror holds


func clear() -> void:
	peer_chunks.clear()
	peer_uids.clear()


func remove_peer(peer_id: int) -> void:
	peer_chunks.erase(peer_id)
	peer_uids.erase(peer_id)


func knows(peer_id: int, uid: int) -> bool:
	return peer_uids.get(peer_id, {}).has(uid)


func sees_chunk(peer_id: int, chunk_key: String) -> bool:
	return peer_chunks.get(peer_id, {}).has(chunk_key)


func mark_known(peer_id: int, uid: int) -> void:
	if not peer_uids.has(peer_id):
		peer_uids[peer_id] = {}
	peer_uids[peer_id][uid] = true


func forget(peer_id: int, uid: int) -> bool:
	return peer_uids.get(peer_id, {}).erase(uid)


## Moves the peer's window to the chunk containing pos. Returns the chunk keys that were added and dropped.
func update_chunks(peer_id: int, pos: Array) -> Dictionary:
	var center := WorldEntityIndex.chunk_coords(pos)
	var current: Dictionary = peer_chunks.get(peer_id, {})
	var entered: Array = []
	var exited: Array = []
	for dx in range(-ENTER_RADIUS, ENTER_RADIUS + 1):
		for dz in range(-ENTER_RADIUS, ENTER_RADIUS + 1):
			var key := WorldEntityIndex.chunk_key(center.x + dx, center.y + dz)
			if not current.has(key):
				current[key] = true
				entered.append(key)
	for key in current.keys():
		var parts: PackedStringArray = String(key).split(",")
		if maxi(absi(int(parts[0]) - center.x), absi(int(parts[1]) - center.y)) > EXIT_RADIUS:
			current.erase(key)
			exited.append(key)
	peer_chunks[peer_id] = current
	if not peer_uids.has(peer_id):
		peer_uids[peer_id] = {}
	return {"entered": entered, "exited": exited}
