extends RefCounted

const BoundaryDao = preload("res://world/simulation/traits/boundary_dao.gd")


static func execute(world, player: Dictionary, args: Dictionary, _def) -> bool:
	if not BoundaryDao.is_in_shadow(world, player):
		return false
	if not BoundaryDao.in_boundary(player):
		return false
	var dir := _resolve_direction(player, args)
	var limit: float = world.map_half() - 1.0
	var nx := clampf(float(player.position[0]) + dir.x * 6.0, -limit, limit)
	var nz := clampf(float(player.position[2]) + dir.y * 6.0, -limit, limit)
	player["position"] = [nx, 0.0, nz]
	player["_teleported"] = true
	return true


static func _resolve_direction(player: Dictionary, args: Dictionary) -> Vector2:
	var raw_pos = args.get("position", [])
	if raw_pos is Array and raw_pos.size() >= 3:
		var delta := Vector2(float(raw_pos[0]) - float(player.position[0]), float(raw_pos[2]) - float(player.position[2]))
		if delta.length() > 0.05:
			return delta.normalized()
	var raw_dir = args.get("direction", [1.0, 0.0])
	if raw_dir is Array and raw_dir.size() >= 2:
		var vec := Vector2(float(raw_dir[0]), float(raw_dir[1]))
		if vec.length() > 0.05:
			return vec.normalized()
	return Vector2(1.0, 0.0)
