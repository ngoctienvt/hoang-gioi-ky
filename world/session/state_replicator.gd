class_name StateReplicator
extends RefCounted
## Host side of state replication. Every network tick it turns the world's dirty set into one patch
## per peer, holding only entities inside that peer's area of interest. Moving creatures go in a
## separate packed position list for the unreliable channel. The client side is ReplicaMirror.

const Interest = preload("res://world/session/interest_grid.gd")

const ENTITY_COLLECTIONS := ["nodes", "drops", "structures", "creatures", "puppets", "npcs"]
## World-wide fields sent whole, but only when their content hash changes.
const SHARED_GROUPS := ["discovered", "regions", "teleports", "karma", "forbidden_recipes", "rituals", "secret_realm", "weather"]
## Host-only bookkeeping on entities. Never sent, so changing it needs no touch(). Any key starting with
## "_" (at any depth, e.g. the raw freshness "_f" in item slots) is host-only by the same rule.
const HOST_ONLY_FIELDS := ["cooldown", "noise_alert", "provoked", "home", "stolen", "target_uid", "aggro_pos",
	"cracked_timer", "grounded_timer", "channel_timer", "respawn"]
## Countdowns the host only re-sends when they cross a whole second, so a mirror may lag by under 1 s.
const COARSE_TIMERS := ["fuel", "remaining", "regrow", "age", "melt", "burning", "health", "growth"]
## Key inside a per-field delta listing the fields the receiver must erase.
const REMOVED_KEY := "~removed"
## Weather countdowns tick every frame; clients only need the kind and the warning areas.
const WEATHER_VOLATILE := ["timer", "lightning_cd", "fire_cd"]
## What another player's mirror needs to draw and target a teammate. The owner gets the full record.
const PUBLIC_PLAYER_FIELDS := ["name", "position", "character", "ghost", "beast_time", "hit_flash", "biome",
	"in_secret_realm", "awakening_tier"]

var interest := Interest.new()
var peer_meta: Dictionary = {}  # peer_id -> {group: hash, "clock": {field: hash}, "players": {pid: {field: hash}}}


func reset_host() -> void:
	interest.clear()
	peer_meta.clear()


func remove_peer(peer_id: int) -> void:
	interest.remove_peer(peer_id)
	peer_meta.erase(peer_id)


## Full join payload: shared groups plus every entity in the peer's starting area.
func initial_payload(world: GameWorld, peer_id: int) -> Dictionary:
	remove_peer(peer_id)
	var packets := step_host(world, [peer_id], false)
	var patch: Dictionary = packets[peer_id].patch
	patch["seed"] = world.state.seed
	patch["options"] = world.state.options.duplicate(true)
	return patch


## Builds {peer_id: {"patch": Dictionary, "positions": Array}}. consume=false leaves the world's dirty
## set untouched (used for a join in the middle of a tick).
func step_host(world: GameWorld, peer_ids: Array, consume: bool = true) -> Dictionary:
	var changes: Dictionary = world.index.consume_dirty() if consume else {"dirty": [], "removed": [], "moved_creatures": [], "chunk_changed": []}
	var group_hashes := _group_hashes(world.state)
	var out: Dictionary = {}
	for peer_id in peer_ids:
		out[peer_id] = _peer_packet(world, int(peer_id), changes, group_hashes)
	return out


func _peer_packet(world: GameWorld, peer_id: int, changes: Dictionary, group_hashes: Dictionary) -> Dictionary:
	var index: WorldEntityIndex = world.index
	var player: Dictionary = world.state.players.get(str(peer_id), {})
	var window := interest.update_chunks(peer_id, player.get("position", [0.0, 0.0, 0.0]))
	var upsert: Dictionary = {}
	var remove: Dictionary = {}
	for key in window.entered:
		for uid in index.uids_in_chunk(key):
			_reconcile(world, peer_id, uid, false, upsert, remove)
	for key in window.exited:
		for uid in index.uids_in_chunk(key):
			_reconcile(world, peer_id, uid, false, upsert, remove)
	for uid in changes.removed:
		if interest.forget(peer_id, uid):
			remove[uid] = true
	for uid in changes.chunk_changed:
		_reconcile(world, peer_id, uid, false, upsert, remove)
	for uid in changes.dirty:
		_reconcile(world, peer_id, uid, true, upsert, remove)
	var positions: Array = []
	for uid in changes.moved_creatures:
		if upsert.has(uid) or not interest.knows(peer_id, uid):
			continue
		var entity: Dictionary = index.find(uid)
		if entity.is_empty():
			continue
		positions.append(int(uid))
		positions.append(snappedf(float(entity.position[0]), 0.01))
		positions.append(snappedf(float(entity.position[2]), 0.01))
		index.last_sent_pos[uid] = entity.position.duplicate()
	var meta: Dictionary = peer_meta.get(peer_id, {})
	var patch := {}
	var players := _players_for(world, peer_id, meta)
	if not players.players.is_empty():
		patch["players"] = players.players
	if not players.players_left.is_empty():
		patch["players_left"] = players.players_left
	var clock_delta := _field_delta(world.state.clock, meta.get("clock", {}))
	if not clock_delta.is_empty():
		patch["clock"] = clock_delta.duplicate(true)
		var clock_hashes: Dictionary = meta.get("clock", {})
		_remember_delta(clock_hashes, clock_delta)
		meta["clock"] = clock_hashes
	if not upsert.is_empty():
		patch["upsert"] = upsert.values()
	if not remove.is_empty():
		patch["remove"] = remove.keys()
	for group in SHARED_GROUPS:
		if meta.get(group, null) != group_hashes[group]:
			meta[group] = group_hashes[group]
			patch[group] = _shared_value(world.state, group)
	peer_meta[peer_id] = meta
	return {"patch": patch, "positions": positions}


## Decides whether the peer should hold uid right now and records the upsert/remove that makes it so.
func _reconcile(world: GameWorld, peer_id: int, uid: int, changed: bool, upsert: Dictionary, remove: Dictionary) -> void:
	var entity: Dictionary = world.index.find(uid)
	var should := not entity.is_empty() and interest.sees_chunk(peer_id, world.index.entity_chunk.get(uid, "")) \
		and _visible_to_peer(entity, peer_id)
	var known := interest.knows(peer_id, uid)
	if should and (changed or not known):
		interest.mark_known(peer_id, uid)
		upsert[uid] = public_entity(entity, world.index.collection_of.get(uid, "nodes"))
		remove.erase(uid)
	elif not should and known:
		interest.forget(peer_id, uid)
		upsert.erase(uid)
		remove[uid] = true


static func public_entity(entity: Dictionary, collection: String) -> Dictionary:
	var copy: Dictionary = strip_private(entity)
	for key in HOST_ONLY_FIELDS:
		copy.erase(key)
	copy["collection"] = collection
	return copy


## Deep copy without "_"-prefixed keys.
static func strip_private(value):
	if value is Dictionary:
		var out := {}
		for key in value:
			if not str(key).begins_with("_"):
				out[key] = strip_private(value[key])
		return out
	if value is Array:
		var arr: Array = []
		for item in value:
			arr.append(strip_private(item))
		return arr
	return value


## Per-field delta of every player record: a field is sent only when its hash differs from what this
## peer last received. "players_left" lists records the peer should drop.
func _players_for(world: GameWorld, peer_id: int, meta: Dictionary) -> Dictionary:
	var sent: Dictionary = meta.get("players", {})
	var delta: Dictionary = {}
	var self_key := str(peer_id)
	for pid in world.state.players:
		var pdata: Dictionary = world.state.players[pid]
		var record: Dictionary = strip_private(pdata) if pid == self_key else public_player(pdata)
		var changed := _field_delta(record, sent.get(pid, {}))
		if not changed.is_empty():
			delta[pid] = changed
	var left: Array = []
	for pid in sent.keys():
		if not world.state.players.has(pid):
			sent.erase(pid)
			left.append(pid)
	for pid in delta:
		if not sent.has(pid):
			sent[pid] = {}
		_remember_delta(sent[pid], delta[pid])
	meta["players"] = sent
	return {"players": delta, "players_left": left}


## Fields of record whose hash differs from previous_hashes. Fields that disappeared are listed
## under REMOVED_KEY so the mirror erases them too.
static func _field_delta(record: Dictionary, previous_hashes: Dictionary) -> Dictionary:
	var out := {}
	for key in record:
		if previous_hashes.get(key, null) != hash(record[key]):
			out[key] = record[key]
	var gone: Array = []
	for key in previous_hashes:
		if not record.has(key):
			gone.append(key)
	if not gone.is_empty():
		out[REMOVED_KEY] = gone
	return out


## Records the hashes of a delta produced by _field_delta into hashes.
static func _remember_delta(hashes: Dictionary, delta: Dictionary) -> void:
	for key in delta:
		if key == REMOVED_KEY:
			for gone in delta[key]:
				hashes.erase(gone)
		else:
			hashes[key] = hash(delta[key])


static func public_player(pdata: Dictionary) -> Dictionary:
	var out := {"uid": pdata.get("uid", 0), "kind": "player"}
	for key in PUBLIC_PLAYER_FIELDS:
		if pdata.has(key):
			out[key] = pdata[key]
	var equipment: Dictionary = pdata.get("inventory", {}).get("equipment", {})
	var shown := {}
	for slot in ["hand", "body", "head"]:
		var item = equipment.get(slot)
		if item is Dictionary and not item.is_empty():
			shown[slot] = {"id": item.get("id", "")}
	out["inventory"] = {"equipment": shown}
	return out


func _group_hashes(state: Dictionary) -> Dictionary:
	var out := {}
	for group in SHARED_GROUPS:
		out[group] = hash(_shared_value(state, group))
	return out


static func _shared_value(state: Dictionary, group: String):
	var value = state.get(group, {} if group in ["karma", "secret_realm", "weather"] else [])
	if group == "weather" and value is Dictionary:
		var trimmed: Dictionary = value.duplicate(true)
		for key in WEATHER_VOLATILE:
			trimmed.erase(key)
		for warning in trimmed.get("warnings", []):
			if warning is Dictionary:
				warning.erase("timer")
		return trimmed
	return value.duplicate(true) if value is Dictionary or value is Array else value


static func _visible_to_peer(entity: Dictionary, peer_id: int) -> bool:
	if not entity.get("private_to_owner", false):
		return true
	return int(entity.get("owner_peer", 0)) == peer_id
