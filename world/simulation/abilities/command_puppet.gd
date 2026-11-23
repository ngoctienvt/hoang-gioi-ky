extends RefCounted

const PuppeteerCraft = preload("res://world/simulation/traits/puppeteer_craft.gd")


static func execute(world, player: Dictionary, args: Dictionary, _def) -> bool:
	var peer_id := -int(player.uid)
	var guards := PuppeteerCraft.guard_puppets(world, peer_id)
	if guards.is_empty():
		return false
	var target := _resolve_target(world, player, args)
	if target.is_empty():
		return false
	for puppet in guards:
		puppet["target_uid"] = int(target.uid)
		puppet["state"] = "attack"
		world.touch(int(puppet.uid))
	return true


static func _resolve_target(world, player: Dictionary, args: Dictionary) -> Dictionary:
	var uid = args.get("uid", -1)
	if (uid is int or uid is float) and int(uid) > 0:
		var direct: Dictionary = world.find_any(uid)
		var col: String = world.index.collection_of.get(int(uid), "")
		if not direct.is_empty() and col in ["creatures", "npcs"] and world.near(player, direct, 15.0):
			if _valid_target(col, direct):
				return direct
	var best: Dictionary = {}
	var best_d := 15.0001
	for col in ["creatures", "npcs"]:
		for e in world.index.entities_near(player.position, 15.0, col):
			if not _valid_target(col, e):
				continue
			var d: float = world.distance(player.position, e.position)
			if d < best_d:
				best_d = d
				best = e
	return best


static func _valid_target(col: String, entity: Dictionary) -> bool:
	if float(entity.get("health", 0.0)) <= 0.0:
		return false
	if col == "creatures":
		return str(entity.get("state", "")) != "dead" and not entity.get("ally", false)
	return bool(entity.get("hostile", false))
