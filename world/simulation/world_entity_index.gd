class_name WorldEntityIndex
extends RefCounted

const CHUNK_SIZE := 24.0

var by_uid: Dictionary = {}
var collection_of: Dictionary = {}
var chunks: Dictionary = {}
var entity_chunk: Dictionary = {}
var dirty: Dictionary = {}
var removed: Dictionary = {}
var moved_creatures: Dictionary = {}
## Entities whose chunk changed since the last consume; replication re-checks interest for them.
var chunk_changed: Dictionary = {}
## Last position published per moving entity, so sub-threshold drift is not resent every tick.
var last_sent_pos: Dictionary = {}


static func chunk_coords(pos: Array) -> Vector2i:
	if pos.size() < 3:
		return Vector2i.ZERO
	return Vector2i(int(floor(float(pos[0]) / CHUNK_SIZE)), int(floor(float(pos[2]) / CHUNK_SIZE)))


static func chunk_key(cx: int, cz: int) -> String:
	return "%d,%d" % [cx, cz]


func clear() -> void:
	by_uid.clear()
	collection_of.clear()
	chunks.clear()
	entity_chunk.clear()
	dirty.clear()
	removed.clear()
	moved_creatures.clear()
	chunk_changed.clear()
	last_sent_pos.clear()


func rebuild(state: Dictionary) -> void:
	clear()
	for collection in ["nodes", "drops", "structures", "creatures", "puppets", "npcs"]:
		for entity in state.get(collection, []):
			_index_existing(collection, entity)


func _index_existing(collection: String, entity: Dictionary) -> void:
	var uid := int(entity.get("uid", 0))
	if uid <= 0:
		return
	by_uid[uid] = entity
	collection_of[uid] = collection
	var c := chunk_coords(entity.get("position", [0.0, 0.0, 0.0]))
	var key := chunk_key(c.x, c.y)
	entity_chunk[uid] = key
	if not chunks.has(key):
		chunks[key] = {}
	chunks[key][uid] = true


func add(collection: String, entity: Dictionary) -> void:
	_index_existing(collection, entity)
	var uid := int(entity.get("uid", 0))
	if uid > 0:
		removed.erase(uid)
		dirty[uid] = true


func remove(uid: int) -> void:
	if not by_uid.has(uid):
		return
	var key: String = entity_chunk.get(uid, "")
	if not key.is_empty() and chunks.has(key):
		chunks[key].erase(uid)
		if chunks[key].is_empty():
			chunks.erase(key)
	entity_chunk.erase(uid)
	by_uid.erase(uid)
	collection_of.erase(uid)
	dirty.erase(uid)
	moved_creatures.erase(uid)
	chunk_changed.erase(uid)
	last_sent_pos.erase(uid)
	removed[uid] = true


func update_position(entity: Dictionary) -> void:
	var uid := int(entity.get("uid", 0))
	if uid <= 0 or not by_uid.has(uid):
		return
	var c := chunk_coords(entity.get("position", [0.0, 0.0, 0.0]))
	var new_key := chunk_key(c.x, c.y)
	var old_key: String = entity_chunk.get(uid, "")
	if new_key != old_key:
		if not old_key.is_empty() and chunks.has(old_key):
			chunks[old_key].erase(uid)
			if chunks[old_key].is_empty():
				chunks.erase(old_key)
		if not chunks.has(new_key):
			chunks[new_key] = {}
		chunks[new_key][uid] = true
		entity_chunk[uid] = new_key
		chunk_changed[uid] = true


func touch(uid: int) -> void:
	if uid > 0 and by_uid.has(uid):
		dirty[uid] = true


func mark_creature_moved(uid: int) -> void:
	if uid <= 0 or not by_uid.has(uid):
		return
	var pos: Array = by_uid[uid].get("position", [0.0, 0.0, 0.0])
	var prev = last_sent_pos.get(uid)
	if prev is Array and prev.size() >= 3:
		var dx := float(pos[0]) - float(prev[0])
		var dz := float(pos[2]) - float(prev[2])
		if dx * dx + dz * dz < 0.04:
			return
	last_sent_pos[uid] = pos.duplicate()
	moved_creatures[uid] = true


func find(uid) -> Dictionary:
	if not (uid is int or uid is float):
		return {}
	return by_uid.get(int(uid), {})


func find_in(collection: String, uid) -> Dictionary:
	if not (uid is int or uid is float):
		return {}
	var key := int(uid)
	if collection_of.get(key, "") != collection:
		return {}
	return by_uid.get(key, {})


func uids_in_chunk(key: String) -> Array:
	if not chunks.has(key):
		return []
	return chunks[key].keys()


func entities_near(pos: Array, radius: float, collection: String = "") -> Array:
	var result: Array = []
	if pos.size() < 3:
		return result
	var px := float(pos[0])
	var pz := float(pos[2])
	var r_sq := radius * radius
	var min_cx := int(floor((px - radius) / CHUNK_SIZE))
	var max_cx := int(floor((px + radius) / CHUNK_SIZE))
	var min_cz := int(floor((pz - radius) / CHUNK_SIZE))
	var max_cz := int(floor((pz + radius) / CHUNK_SIZE))
	for cx in range(min_cx, max_cx + 1):
		for cz in range(min_cz, max_cz + 1):
			var key := chunk_key(cx, cz)
			if not chunks.has(key):
				continue
			for uid in chunks[key]:
				if not collection.is_empty() and collection_of.get(uid, "") != collection:
					continue
				var e: Dictionary = by_uid[uid]
				var ep: Array = e.position
				var dx := float(ep[0]) - px
				var dz := float(ep[2]) - pz
				if dx * dx + dz * dz <= r_sq:
					result.append(e)
	return result


func consume_dirty() -> Dictionary:
	var out := {
		"dirty": dirty.keys(),
		"removed": removed.keys(),
		"moved_creatures": moved_creatures.keys(),
		"chunk_changed": chunk_changed.keys(),
	}
	dirty.clear()
	removed.clear()
	moved_creatures.clear()
	chunk_changed.clear()
	return out
