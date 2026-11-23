extends RefCounted

const BoundaryDao = preload("res://world/simulation/traits/boundary_dao.gd")


static func execute(world, player: Dictionary, args: Dictionary, _def) -> bool:
	if not BoundaryDao.in_boundary(player):
		return false
	var target := _resolve_target(world, player, args)
	if target.is_empty():
		return false
	var dao := float(player.stats.get("dao", 50.0))
	var damage := 18.0 + absf(dao - 50.0) * 1.5
	var col: String = world.index.collection_of.get(int(target.get("uid", 0)), "")
	target.health = float(target.health) - damage
	target.hit_flash = 0.2
	if col == "creatures":
		world.Creatures.on_creature_hurt(world, target, player)
		var limit: float = world.map_half() - 1.0
		var away := Vector3(target.position[0] - player.position[0], 0, target.position[2] - player.position[2]).normalized()
		var new_pos := [clampf(target.position[0] + away.x * 0.6, -limit, limit), 0.0, clampf(target.position[2] + away.z * 0.6, -limit, limit)]
		world.move_entity(target, new_pos, true)
		if float(target.health) <= 0.0:
			world.Combat.kill(world, target)
	elif col == "npcs":
		if float(target.health) <= 0.0:
			world.Npcs.kill(world, target)
		else:
			world.touch(int(target.uid))
	return true


static func _resolve_target(world, player: Dictionary, args: Dictionary) -> Dictionary:
	var uid = args.get("uid", -1)
	if (uid is int or uid is float) and int(uid) > 0:
		var direct: Dictionary = world.find_any(uid)
		var col: String = world.index.collection_of.get(int(uid), "")
		if not direct.is_empty() and col in ["creatures", "npcs"] and world.near(player, direct, 3.2):
			if float(direct.get("health", 0.0)) > 0.0 and (col == "creatures" or bool(direct.get("hostile", false))):
				return direct
	var best: Dictionary = {}
	var best_d := 3.2001
	for col in ["creatures", "npcs"]:
		for e in world.index.entities_near(player.position, 3.2, col):
			if float(e.get("health", 0.0)) <= 0.0:
				continue
			if col == "creatures" and str(e.get("state", "")) == "dead":
				continue
			if col == "npcs" and not bool(e.get("hostile", false)):
				continue
			var d: float = world.distance(player.position, e.position)
			if d < best_d:
				best_d = d
				best = e
	return best
