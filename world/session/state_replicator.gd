class_name StateReplicator
extends RefCounted

const Interest = preload("res://world/session/interest_grid.gd")

var interest := Interest.new()
var peer_meta: Dictionary = {}

# Client-side state
var client_entities: Dictionary = {}
var client_state: Dictionary = {}


func reset_host() -> void:
	interest.clear()
	peer_meta.clear()


func remove_peer(peer_id: int) -> void:
	interest.remove_peer(peer_id)
	peer_meta.erase(peer_id)


func initial_payload(world: GameWorld, peer_id: int) -> Dictionary:
	var player: Dictionary = world.state.players.get(str(peer_id), {})
	var pos: Array = player.get("position", [0.0, 0.0, 0.0])
	interest.remove_peer(peer_id)
	var delta := interest.update_peer(peer_id, pos, world.index)
	var upsert: Array = []
	for uid in delta.entered:
		var entity: Dictionary = world.index.find(uid)
		if not entity.is_empty() and _visible_to_peer(entity, peer_id):
			var copy := entity.duplicate(true)
			copy["collection"] = world.index.collection_of.get(int(uid), "nodes")
			upsert.append(copy)
	var discovered: Array = world.state.get("discovered", []).duplicate()
	var events: Array = world.state.get("events", []).duplicate(true)
	var regions: Array = world.state.get("regions", []).duplicate(true)
	var teleports: Array = world.state.get("teleports", []).duplicate(true)
	var karma: Dictionary = world.state.get("karma", {"sin": 0.0, "fate": 0.0}).duplicate(true)
	var forbidden: Array = world.state.get("forbidden_recipes", []).duplicate()
	var rituals: Array = world.state.get("rituals", []).duplicate(true)
	var secret_realm: Dictionary = world.state.get("secret_realm", {}).duplicate(true)
	peer_meta[peer_id] = {
		"discovered_size": discovered.size(),
		"events_sig": str(events.back()) if not events.is_empty() else "",
		"regions_size": regions.size(),
		"teleports_sig": str(teleports),
		"weather_sig": str(world.state.get("weather", {})),
		"karma_sig": str(karma),
		"forbidden_size": forbidden.size(),
		"rituals_sig": str(rituals),
		"secret_realm_sig": str(secret_realm),
		"inv_sigs": _player_inv_sigs(world.state.players),
	}
	return {
		"seed": world.state.seed,
		"options": world.state.options.duplicate(true),
		"clock": world.state.clock.duplicate(true),
		"weather": world.state.get("weather", {}).duplicate(true),
		"players": world.state.players.duplicate(true),
		"discovered": discovered,
		"events": events,
		"regions": regions,
		"teleports": teleports,
		"karma": karma,
		"forbidden_recipes": forbidden,
		"rituals": rituals,
		"secret_realm": secret_realm,
		"upsert": upsert,
	}


func step_host(world: GameWorld, peer_ids: Array) -> Dictionary:
	var changes := world.index.consume_dirty()
	var dirty_uids: Array = changes.dirty
	var removed_uids: Array = changes.removed
	var moved_creatures: Array = changes.moved_creatures

	var discovered: Array = world.state.get("discovered", [])
	var events: Array = world.state.get("events", [])
	var events_sig := str(events.back()) if not events.is_empty() else ""
	var regions: Array = world.state.get("regions", [])
	var teleports: Array = world.state.get("teleports", [])
	var teleports_sig := str(teleports)

	var out: Dictionary = {}
	for peer_id in peer_ids:
		var player: Dictionary = world.state.players.get(str(peer_id), {})
		var pos: Array = player.get("position", [0.0, 0.0, 0.0])
		var delta := interest.update_peer(peer_id, pos, world.index)

		var upsert_set: Dictionary = {}
		var remove_set: Dictionary = {}

		for uid in delta.entered:
			upsert_set[uid] = true
		for uid in delta.exited:
			remove_set[uid] = true
		for uid in removed_uids:
			if interest.untrack_uid(peer_id, uid):
				remove_set[uid] = true
				upsert_set.erase(uid)

		for uid in dirty_uids:
			var chunk_key: String = world.index.entity_chunk.get(uid, "")
			var in_interest := interest.has_uid(peer_id, uid)
			if not in_interest and not chunk_key.is_empty():
				in_interest = interest.track_uid(peer_id, uid, chunk_key)
			if in_interest:
				upsert_set[uid] = true
				remove_set.erase(uid)
			elif interest.untrack_uid(peer_id, uid):
				remove_set[uid] = true

		var upsert: Array = []
		for uid in upsert_set:
			var entity: Dictionary = world.index.find(uid)
			if not entity.is_empty() and _visible_to_peer(entity, peer_id):
				var copy := entity.duplicate(true)
				copy["collection"] = world.index.collection_of.get(int(uid), "nodes")
				upsert.append(copy)

		var positions: Array = []
		for uid in moved_creatures:
			if upsert_set.has(uid):
				continue
			var chunk_key: String = world.index.entity_chunk.get(uid, "")
			var in_interest := interest.has_uid(peer_id, uid)
			if not in_interest and not chunk_key.is_empty():
				in_interest = interest.track_uid(peer_id, uid, chunk_key)
				if in_interest:
					var entered_c: Dictionary = world.index.find(uid)
					if not entered_c.is_empty() and _visible_to_peer(entered_c, peer_id):
						var c_copy := entered_c.duplicate(true)
						c_copy["collection"] = world.index.collection_of.get(int(uid), "creatures")
						upsert.append(c_copy)
					continue
			if in_interest:
				var c: Dictionary = world.index.find(uid)
				if not c.is_empty() and _visible_to_peer(c, peer_id):
					positions.append(int(uid))
					positions.append(snappedf(float(c.position[0]), 0.01))
					positions.append(snappedf(float(c.position[2]), 0.01))

		var meta: Dictionary = peer_meta.get(peer_id, {})
		var prev_inv_sigs: Dictionary = meta.get("inv_sigs", {})
		var players_patch: Dictionary = {}
		var new_inv_sigs: Dictionary = {}
		var self_key := str(peer_id)
		for pid in world.state.players:
			var pdata: Dictionary = world.state.players[pid]
			if pid != self_key:
				players_patch[pid] = {
					"uid": pdata.uid,
					"kind": "player",
					"name": pdata.name,
					"position": pdata.position,
					"ghost": pdata.get("ghost", false),
					"beast_time": pdata.get("beast_time", 0.0),
					"hit_flash": pdata.get("hit_flash", 0.0),
					"biome": pdata.get("biome", "bamboo_forest"),
				}
				continue
			var inv_sig := str(pdata.get("inventory", {}))
			new_inv_sigs[pid] = inv_sig
			if inv_sig == str(prev_inv_sigs.get(pid, "")):
				var slim := pdata.duplicate(true)
				slim.erase("inventory")
				players_patch[pid] = slim
			else:
				players_patch[pid] = pdata.duplicate(true)
		meta["inv_sigs"] = new_inv_sigs

		var patch: Dictionary = {
			"players": players_patch,
			"clock": world.state.clock.duplicate(true),
		}
		if not upsert.is_empty():
			patch["upsert"] = upsert
		if not remove_set.is_empty():
			patch["remove"] = remove_set.keys()

		if discovered.size() != int(meta.get("discovered_size", -1)):
			patch["discovered"] = discovered.duplicate()
			meta["discovered_size"] = discovered.size()
		if events_sig != str(meta.get("events_sig", "")):
			patch["events"] = events.duplicate(true)
			meta["events_sig"] = events_sig
		if regions.size() != int(meta.get("regions_size", -1)):
			patch["regions"] = regions.duplicate(true)
			meta["regions_size"] = regions.size()
		if teleports_sig != str(meta.get("teleports_sig", "")):
			patch["teleports"] = teleports.duplicate(true)
			meta["teleports_sig"] = teleports_sig
		var weather_data: Dictionary = world.state.get("weather", {})
		var weather_sig := str(weather_data)
		if weather_sig != str(meta.get("weather_sig", "")):
			patch["weather"] = weather_data.duplicate(true)
			meta["weather_sig"] = weather_sig
		var karma: Dictionary = world.state.get("karma", {"sin": 0.0, "fate": 0.0})
		var karma_sig := str(karma)
		if karma_sig != str(meta.get("karma_sig", "")):
			patch["karma"] = karma.duplicate(true)
			meta["karma_sig"] = karma_sig
		var forbidden: Array = world.state.get("forbidden_recipes", [])
		if forbidden.size() != int(meta.get("forbidden_size", -1)):
			patch["forbidden_recipes"] = forbidden.duplicate()
			meta["forbidden_size"] = forbidden.size()
		var rituals: Array = world.state.get("rituals", [])
		var rituals_sig := str(rituals)
		if rituals_sig != str(meta.get("rituals_sig", "")):
			patch["rituals"] = rituals.duplicate(true)
			meta["rituals_sig"] = rituals_sig
		var sr: Dictionary = world.state.get("secret_realm", {})
		var sr_sig := str(sr)
		if sr_sig != str(meta.get("secret_realm_sig", "")):
			patch["secret_realm"] = sr.duplicate(true)
			meta["secret_realm_sig"] = sr_sig
		peer_meta[peer_id] = meta

		out[peer_id] = {"patch": patch, "positions": positions}
	return out


func reset_client() -> void:
	client_entities.clear()
	client_state.clear()


func apply_initial(data: Dictionary) -> Dictionary:
	client_entities.clear()
	client_state = {
		"seed": data.get("seed", 0),
		"options": data.get("options", {}),
		"clock": data.get("clock", {}),
		"weather": data.get("weather", {}),
		"players": data.get("players", {}),
		"discovered": data.get("discovered", []),
		"events": data.get("events", []),
		"regions": data.get("regions", []),
		"teleports": data.get("teleports", []),
		"karma": data.get("karma", {"sin": 0.0, "fate": 0.0}),
		"forbidden_recipes": data.get("forbidden_recipes", []),
		"rituals": data.get("rituals", []),
		"secret_realm": data.get("secret_realm", {}),
		"nodes": [],
		"drops": [],
		"structures": [],
		"creatures": [],
		"puppets": [],
		"npcs": [],
	}
	for entity in data.get("upsert", []):
		client_entities[int(entity.uid)] = entity
	_rebuild_client_collections()
	return client_state


func apply_patch(patch: Dictionary) -> Dictionary:
	if patch.has("players"):
		var prev_players: Dictionary = client_state.get("players", {})
		var next_players: Dictionary = patch["players"]
		for pid in next_players:
			if not next_players[pid].has("inventory") and prev_players.has(pid):
				next_players[pid]["inventory"] = prev_players[pid].get("inventory", {})
		client_state["players"] = next_players
	for key in ["clock", "weather", "discovered", "events", "regions", "teleports", "karma", "forbidden_recipes", "rituals", "secret_realm"]:
		if patch.has(key):
			client_state[key] = patch[key]
	for uid in patch.get("remove", []):
		client_entities.erase(int(uid))
	for entity in patch.get("upsert", []):
		client_entities[int(entity.uid)] = entity
	_rebuild_client_collections()
	return client_state


func apply_positions(positions: Array) -> Dictionary:
	var i := 0
	var count := positions.size()
	while i + 2 < count:
		var uid := int(positions[i])
		if client_entities.has(uid):
			client_entities[uid].position = [float(positions[i + 1]), 0.0, float(positions[i + 2])]
		i += 3
	return client_state


func _rebuild_client_collections() -> void:
	var nodes: Array = []
	var drops: Array = []
	var structures: Array = []
	var creatures: Array = []
	var puppets: Array = []
	var npcs: Array = []
	for entity in client_entities.values():
		var col: String = str(entity.get("collection", "nodes"))
		match col:
			"nodes":
				nodes.append(entity)
			"drops":
				drops.append(entity)
			"structures":
				structures.append(entity)
			"creatures":
				creatures.append(entity)
			"puppets":
				puppets.append(entity)
			"npcs":
				npcs.append(entity)
	client_state["nodes"] = nodes
	client_state["drops"] = drops
	client_state["structures"] = structures
	client_state["creatures"] = creatures
	client_state["puppets"] = puppets
	client_state["npcs"] = npcs


func _visible_to_peer(entity: Dictionary, peer_id: int) -> bool:
	if not entity.get("private_to_owner", false):
		return true
	return int(entity.get("owner_peer", 0)) == peer_id


func _player_inv_sigs(players: Dictionary) -> Dictionary:
	var sigs: Dictionary = {}
	for pid in players:
		sigs[pid] = str(players[pid].get("inventory", {}))
	return sigs
