extends RefCounted

const REALM_ORIGIN := [1200.0, 0.0, 1200.0]
const REALM_HALF := 16.0


static func _has_portal(world) -> bool:
	for n in world.state.get("nodes", []):
		if str(n.get("kind", "")) == "secret_realm_portal":
			return true
	return false


static func _ensure_arena(world) -> void:
	var sr: Dictionary = world.state.get("secret_realm", {})
	if sr.get("built", false):
		return
	var exit_node: Dictionary = world.entity("secret_realm_exit", [REALM_ORIGIN[0], 0.0, REALM_ORIGIN[2] + 8.0])
	exit_node.merge({"in_secret_realm": true})
	world.add_entity("nodes", exit_node)

	var switch_offsets := [[-6.0, -4.0], [0.0, -8.0], [6.0, -4.0]]
	for i in switch_offsets.size():
		var sw: Dictionary = world.entity("realm_switch", [REALM_ORIGIN[0] + switch_offsets[i][0], 0.0, REALM_ORIGIN[2] + switch_offsets[i][1]])
		sw.merge({"active": false, "index": i, "in_secret_realm": true})
		world.add_entity("nodes", sw)

	var chest: Dictionary = world.entity("realm_chest", [REALM_ORIGIN[0], 0.0, REALM_ORIGIN[2] - 11.0])
	chest.merge({"unlocked": false, "claimed": false, "in_secret_realm": true})
	world.add_entity("nodes", chest)

	for gpos in [[-4.0, -6.0], [4.0, -6.0]]:
		var g: Dictionary = world.entity("construct_beast", [REALM_ORIGIN[0] + gpos[0], 0.0, REALM_ORIGIN[2] + gpos[1]])
		g.merge({"health": 90.0, "max_health": 90.0, "state": "idle", "home": g.position.duplicate(), "cooldown": 0.0, "respawn": 0.0, "hit_flash": 0.0, "stolen": [], "effects": {}, "no_respawn": true, "in_secret_realm": true})
		world.add_entity("creatures", g)

	world.state["secret_realm"] = {"built": true, "switches_active": 0, "unlocked": false}


static func enter_realm(world, player: Dictionary, args: Dictionary) -> bool:
	var portal: Dictionary = world.index.find_in("nodes", args.get("uid", -1))
	if portal.is_empty() or str(portal.get("kind", "")) != "secret_realm_portal" or not world.near(player, portal, 3.5):
		return false
	if player.get("in_secret_realm", false):
		return false
	_ensure_arena(world)
	player["realm_return_pos"] = player.position.duplicate()
	player["in_secret_realm"] = true
	player["position"] = REALM_ORIGIN.duplicate()
	player["_teleported"] = true
	world.log_event("secret_realm_entered", {"name": player.name})
	return true


static func exit_realm(world, player: Dictionary, args: Dictionary) -> bool:
	var exit_node: Dictionary = world.index.find_in("nodes", args.get("uid", -1))
	if exit_node.is_empty() or str(exit_node.get("kind", "")) != "secret_realm_exit" or not world.near(player, exit_node, 3.5):
		return false
	if not player.get("in_secret_realm", false):
		return false
	eject_player(world, player)
	return true


static func eject_player(world, player: Dictionary) -> void:
	var ret: Array = player.get("realm_return_pos", [0.0, 0.0, 0.0])
	player["position"] = ret.duplicate() if ret.size() == 3 else [0.0, 0.0, 0.0]
	player["in_secret_realm"] = false
	player["_teleported"] = true


static func activate_switch(world, player: Dictionary, args: Dictionary) -> bool:
	var sw: Dictionary = world.index.find_in("nodes", args.get("uid", -1))
	if sw.is_empty() or str(sw.get("kind", "")) != "realm_switch" or not world.near(player, sw, 3.5):
		return false
	if sw.get("active", false):
		return false
	sw["active"] = true
	world.touch(int(sw.uid))
	var active_count := 0
	for n in world.state.get("nodes", []):
		if str(n.get("kind", "")) == "realm_switch" and n.get("active", false):
			active_count += 1
	var sr: Dictionary = world.state.get("secret_realm", {})
	sr["switches_active"] = active_count
	if active_count >= 3:
		sr["unlocked"] = true
		for n in world.state.get("nodes", []):
			if str(n.get("kind", "")) == "realm_chest":
				n["unlocked"] = true
				world.touch(int(n.uid))
	world.state["secret_realm"] = sr
	return true


static func claim_vault(world, player: Dictionary, args: Dictionary) -> bool:
	var chest: Dictionary = world.index.find_in("nodes", args.get("uid", -1))
	if chest.is_empty() or str(chest.get("kind", "")) != "realm_chest" or not world.near(player, chest, 3.5):
		return false
	if not chest.get("unlocked", false) or chest.get("claimed", false):
		return false
	chest["claimed"] = true
	world.touch(int(chest.uid))
	var inv = world.inventory(player)
	for reward in [["monster_core_high", 2], ["ancient_golem_core", 1], ["spirit_stone", 6]]:
		var left: int = inv.add_item(reward[0], reward[1])
		if left > 0:
			world.drop_item(reward[0], left, player.position)
	player.inventory = inv.to_dict()
	world.log_event("secret_realm_claimed", {"name": player.name})
	return true


static func step(world, delta: float) -> void:
	if bool(world.state.get("options", {}).get("secret_realm", true)) and not _has_portal(world):
		var day := int(world.state.get("clock", {}).get("day", 1))
		var phase := str(world.state.get("clock", {}).get("phase", "day"))
		var wkind := str(world.state.get("weather", {}).get("kind", "clear"))
		if (day % 7 == 0 and phase == "night") or wkind == "storm":
			var portal: Dictionary = world.entity("secret_realm_portal", [8.0, 0.0, 8.0])
			portal.merge({"biome": world.biome_at([8.0, 0.0, 8.0]), "lifetime": world.day_length()})
			world.add_entity("nodes", portal)
	for n in world.state.get("nodes", []).duplicate():
		if str(n.get("kind", "")) == "secret_realm_portal" and n.has("lifetime"):
			n["lifetime"] = float(n.get("lifetime", 0.0)) - delta
			if float(n["lifetime"]) <= 0.0:
				world.remove_entity(n)
				if not _has_portal(world):
					for pl in world.state.players.values():
						if pl.get("in_secret_realm", false):
							eject_player(world, pl)
