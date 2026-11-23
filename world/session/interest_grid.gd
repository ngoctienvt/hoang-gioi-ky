class_name InterestGrid
extends RefCounted

const ENTER_RADIUS := 2
const EXIT_RADIUS := 3

var peer_chunks: Dictionary = {}
var peer_uids: Dictionary = {}


func clear() -> void:
	peer_chunks.clear()
	peer_uids.clear()


func remove_peer(peer_id: int) -> void:
	peer_chunks.erase(peer_id)
	peer_uids.erase(peer_id)


func has_uid(peer_id: int, uid: int) -> bool:
	return peer_uids.get(peer_id, {}).has(uid)


func update_peer(peer_id: int, pos: Array, index: WorldEntityIndex) -> Dictionary:
	var center := WorldEntityIndex.chunk_coords(pos)
	var current_chunks: Dictionary = peer_chunks.get(peer_id, {})
	var current_uids: Dictionary = peer_uids.get(peer_id, {})

	var entered_uids: Array = []
	var exited_uids: Array = []

	# 1. Add chunks within ENTER_RADIUS
	for dx in range(-ENTER_RADIUS, ENTER_RADIUS + 1):
		for dz in range(-ENTER_RADIUS, ENTER_RADIUS + 1):
			var key := WorldEntityIndex.chunk_key(center.x + dx, center.y + dz)
			if not current_chunks.has(key):
				current_chunks[key] = true
				for uid in index.uids_in_chunk(key):
					if not current_uids.has(uid):
						current_uids[uid] = true
						entered_uids.append(uid)

	# 2. Remove chunks beyond EXIT_RADIUS
	for key in current_chunks.keys():
		var parts: PackedStringArray = String(key).split(",")
		var cx := int(parts[0])
		var cz := int(parts[1])
		if maxi(absi(cx - center.x), absi(cz - center.y)) > EXIT_RADIUS:
			current_chunks.erase(key)
			for uid in index.uids_in_chunk(key):
				if current_uids.has(uid):
					current_uids.erase(uid)
					exited_uids.append(uid)

	peer_chunks[peer_id] = current_chunks
	peer_uids[peer_id] = current_uids
	return {"entered": entered_uids, "exited": exited_uids}


func track_uid(peer_id: int, uid: int, entity_chunk_key: String) -> bool:
	var current_chunks: Dictionary = peer_chunks.get(peer_id, {})
	if current_chunks.has(entity_chunk_key):
		if not peer_uids.has(peer_id):
			peer_uids[peer_id] = {}
		peer_uids[peer_id][uid] = true
		return true
	return false


func untrack_uid(peer_id: int, uid: int) -> bool:
	var current_uids: Dictionary = peer_uids.get(peer_id, {})
	if current_uids.has(uid):
		current_uids.erase(uid)
		return true
	return false
