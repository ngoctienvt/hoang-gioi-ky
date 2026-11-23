class_name ReplicaMirror
extends RefCounted
## Client side of state replication: keeps a uid -> entity copy of what the host sent and rebuilds the
## state dictionary the UI and view read (same shape as the host's world state, limited to interest).

const ENTITY_COLLECTIONS := ["nodes", "drops", "structures", "creatures", "puppets", "npcs"]
const SHARED_KEYS := ["seed", "options", "discovered", "regions", "teleports", "karma",
	"forbidden_recipes", "rituals", "secret_realm", "weather"]

var entities: Dictionary = {}
var state: Dictionary = {}


func reset() -> void:
	entities.clear()
	state.clear()


func apply_initial(data: Dictionary) -> Dictionary:
	reset()
	state = {"players": {}, "clock": {}, "karma": {"sin": 0.0, "fate": 0.0}, "weather": {}, "secret_realm": {}}
	return apply_patch(data)


func apply_patch(patch: Dictionary) -> Dictionary:
	_apply_players(patch.get("players", {}), patch.get("players_left", []))
	if patch.has("clock"):
		_merge_fields(state.clock, patch.clock)
	for key in SHARED_KEYS:
		if patch.has(key):
			state[key] = patch[key]
	var structural := false
	for uid in patch.get("remove", []):
		structural = entities.erase(int(uid)) or structural
	for entity in patch.get("upsert", []):
		var uid := int(entity.uid)
		var previous: Dictionary = entities.get(uid, {})
		if previous.is_empty() or previous.get("collection", "") != entity.get("collection", ""):
			structural = true
			entities[uid] = entity
		else:
			# Update in place so collection arrays and view references stay valid.
			previous.clear()
			previous.merge(entity)
	if structural or not state.has("nodes"):
		_rebuild_collections()
	return state


func apply_positions(positions: Array) -> Dictionary:
	var i := 0
	while i + 2 < positions.size():
		var entity: Dictionary = entities.get(int(positions[i]), {})
		if not entity.is_empty():
			entity.position = [float(positions[i + 1]), 0.0, float(positions[i + 2])]
		i += 3
	return state


## Players arrive as per-field deltas: merge into the existing record, drop the ones that left.
func _apply_players(changed: Dictionary, left: Array) -> void:
	var players: Dictionary = state.players
	for pid in left:
		players.erase(pid)
	for pid in changed:
		if not players.has(pid):
			players[pid] = {}
		_merge_fields(players[pid], changed[pid])


static func _merge_fields(target: Dictionary, delta: Dictionary) -> void:
	for key in delta:
		if key == StateReplicator.REMOVED_KEY:
			for gone in delta[key]:
				target.erase(gone)
		else:
			target[key] = delta[key]


func _rebuild_collections() -> void:
	for collection in ENTITY_COLLECTIONS:
		state[collection] = []
	for entity in entities.values():
		var collection := str(entity.get("collection", "nodes"))
		if state.has(collection):
			state[collection].append(entity)
