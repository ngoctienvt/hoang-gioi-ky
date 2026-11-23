extends RefCounted


static func step(world, _delta: float) -> void:
	var teleports: Array = world.state.get("teleports", [])
	if teleports.is_empty():
		return
	for idx in teleports.size():
		var tp_info: Dictionary = teleports[idx]
		if str(tp_info.get("state", "dormant")) == "active":
			continue
		var tp_pos: Array = tp_info.position
		for player in world.state.players.values():
			if player.get("ghost", false):
				continue
			if world.distance(player.position, tp_pos) <= 2.5:
				tp_info.state = "active"
				var node: Dictionary = world.index.find(int(tp_info.uid))
				if not node.is_empty():
					node.state = "active"
					world.touch(int(node.uid))
				world.log_event("teleport_activated", {"uid": tp_info.uid, "biome": tp_info.biome})
				break


static func perform(world, player: Dictionary, args: Dictionary) -> bool:
	var source_uid := int(args.get("uid", -1))
	var target_uid := int(args.get("target_uid", -1))
	if source_uid <= 0 or target_uid <= 0 or source_uid == target_uid:
		return false
	var source: Dictionary = world.index.find_in("nodes", source_uid)
	var dest: Dictionary = world.index.find_in("nodes", target_uid)
	if source.is_empty() or dest.is_empty():
		return false
	if str(source.get("kind", "")) != "teleport_array" or str(dest.get("kind", "")) != "teleport_array":
		return false
	if str(source.get("state", "dormant")) != "active" or str(dest.get("state", "dormant")) != "active":
		return false
	if not world.near(player, source, 3.5):
		return false
	var inv = world.inventory(player)
	if not inv.remove_item("spirit_stone", 1):
		return false
	player.inventory = inv.to_dict()
	var dest_pos: Array = dest.position
	player.position = [float(dest_pos[0]) + 1.5, 0.0, float(dest_pos[2])]
	player.biome = world.biome_at(player.position)
	world.log_event("teleport", {"from": source_uid, "to": target_uid, "biome": player.biome})
	return true
