extends RefCounted
const Resources = preload("res://world/simulation/world_resources.gd")


static func tick(world, puppet: Dictionary, delta: float) -> void:
	var zone_center := _zone_center(world, puppet)
	var radius := 8.0
	var task := str(puppet.get("task", "haul"))
	puppet.action_cd = maxf(0.0, float(puppet.get("action_cd", 0.0)) - delta)
	var dest: Array = []
	if task == "haul":
		dest = _tick_haul(world, puppet, zone_center, radius)
	elif task == "chop":
		dest = _tick_gather(world, puppet, zone_center, radius, ["tree", "bamboo", "ancient_pine", "snow_pine", "charred_tree", "rotten_tree"], 1)
	elif task == "mine":
		dest = _tick_gather(world, puppet, zone_center, radius, ["rock", "spirit_rock", "basalt_rock", "dark_iron_vein", "quartz_rock"], 2)
	elif task == "guard":
		dest = _tick_guard(world, puppet)
	if dest.is_empty():
		puppet.state = "idle"
		return
	var moved := _move_with_avoidance(world, puppet, dest, float(puppet.get("speed", 2.0)) * delta, delta)
	if moved:
		world.move_entity(puppet, puppet.position, false)


static func _zone_center(world, puppet: Dictionary) -> Array:
	var stake_uid := int(puppet.get("stake_uid", 0))
	if stake_uid > 0:
		var stake: Dictionary = world.index.find_in("structures", stake_uid)
		if not stake.is_empty():
			return stake.position
	return puppet.get("home", puppet.position)


static func _tick_haul(world, puppet: Dictionary, center: Array, radius: float) -> Array:
	var carrying: Dictionary = puppet.get("carrying", {})
	if carrying.is_empty():
		var drop := _nearest_drop(world, puppet.position, center, radius)
		if drop.is_empty():
			return []
		puppet.state = "haul"
		if world.distance(puppet.position, drop.position) <= 1.2:
			puppet.carrying = {"id": drop.id, "count": int(drop.count), "extra": world.Access.extra(drop.get("extra", {}))}
			world.remove_entity(drop)
			world.touch(int(puppet.uid))
			return []
		return drop.position
	var chest := _nearest_chest(world, center, 12.0)
	if chest.is_empty():
		return []
	puppet.state = "return"
	if world.distance(puppet.position, chest.position) <= 1.6:
		var storage = world.inventory({"inventory": {"slots": chest.slots, "equipment": {}}})
		var left: int = storage.add_item(str(carrying.id), int(carrying.count), carrying.get("extra", {}))
		chest.slots = storage.to_dict().slots
		world.touch(int(chest.uid))
		if left <= 0:
			puppet.carrying = {}
		else:
			puppet.carrying.count = left
		world.touch(int(puppet.uid))
		return []
	return chest.position


static func _tick_gather(world, puppet: Dictionary, center: Array, radius: float, kinds: Array, tool_type: int) -> Array:
	var target: Dictionary = {}
	var best_d := radius + 1.0
	for node in world.index.entities_near(center, radius, "nodes"):
		if node.get("depleted", false) or node.get("sapling", false) or float(node.get("regrow", 0.0)) > 0.0:
			continue
		if str(node.kind) not in kinds:
			continue
		var d: float = world.distance(puppet.position, node.position)
		if d < best_d:
			best_d = d
			target = node
	if target.is_empty():
		return []
	puppet.state = "work"
	if best_d <= 2.0:
		if float(puppet.get("action_cd", 0.0)) <= 0.0:
			puppet.action_cd = 1.0
			_work_node(world, target, tool_type)
		return []
	return target.position


static func _work_node(world, node: Dictionary, _tool_type: int) -> void:
	var definition = world.Rules.node(str(node.kind))
	if definition == null or definition.stages.is_empty():
		return
	var stage = definition.stages[mini(int(node.get("stage", 0)), definition.stages.size() - 1)]
	node.hits = int(node.get("hits", 0)) + 1
	if node.hits >= int(stage.work_hits):
		Resources.complete_stage(world, node, definition, stage)
	if not world.index.find(int(node.uid)).is_empty():
		world.touch(int(node.uid))


static func _nearest_drop(world, from_pos: Array, center: Array, radius: float) -> Dictionary:
	var best: Dictionary = {}
	var best_d := 1e9
	for d in world.index.entities_near(center, radius, "drops"):
		var dist: float = world.distance(from_pos, d.position)
		if dist < best_d:
			best_d = dist
			best = d
	return best


static func _nearest_chest(world, center: Array, radius: float) -> Dictionary:
	var best: Dictionary = {}
	var best_d := 1e9
	for s in world.index.entities_near(center, radius, "structures"):
		if s.kind in ["chest", "talisman_chest"]:
			var dist: float = world.distance(center, s.position)
			if dist < best_d:
				best_d = dist
				best = s
	return best


static func _move_with_avoidance(world, puppet: Dictionary, dest: Array, amount: float, delta: float) -> bool:
	var limit: float = world.map_half() - 1.0
	var src := Vector3(float(puppet.position[0]), 0.0, float(puppet.position[2]))
	var dst := Vector3(float(dest[0]), 0.0, float(dest[2]))
	var dir := dst - src
	if dir.length() < 0.001:
		return false
	var detour_t := float(puppet.get("detour_time", 0.0))
	if detour_t > 0.0:
		puppet.detour_time = detour_t - delta
		dir = dir.rotated(Vector3.UP, float(puppet.get("detour_angle", 0.0)))
	var step_vec := dir.normalized() * minf(amount, dir.length())
	var nx := clampf(src.x + step_vec.x, -limit, limit)
	var nz := clampf(src.z + step_vec.z, -limit, limit)
	var moved_dist := Vector2(nx - src.x, nz - src.z).length()
	if moved_dist < 0.005 * delta * 10.0 and dir.length() > 0.2:
		puppet.stuck_timer = float(puppet.get("stuck_timer", 0.0)) + delta
		if float(puppet.stuck_timer) >= 1.0:
			puppet.stuck_timer = 0.0
			puppet.detour_angle = float(puppet.get("detour_angle", 0.0)) + PI * 0.25
			puppet.detour_time = 1.5
	else:
		puppet.stuck_timer = 0.0
	puppet.position = [nx, 0.0, nz]
	return moved_dist > 0.0001


static func _tick_guard(world, puppet: Dictionary) -> Array:
	var owner_peer := int(puppet.get("owner_peer", 1))
	var owner: Dictionary = world.state.players.get(str(owner_peer), {})
	var anchor: Array = owner.position if not owner.is_empty() else puppet.get("home", puppet.position)
	var target: Dictionary = {}
	var tuid := int(puppet.get("target_uid", 0))
	if tuid > 0:
		var cand: Dictionary = world.find_any(tuid)
		var col: String = world.index.collection_of.get(tuid, "")
		if not cand.is_empty() and col in ["creatures", "npcs"] and float(cand.get("health", 0.0)) > 0.0 and str(cand.get("state", "")) != "dead":
			target = cand
		else:
			puppet["target_uid"] = 0
	if target.is_empty():
		var best_d := 8.5
		for c in world.index.entities_near(anchor, 8.0, "creatures"):
			if float(c.get("health", 0.0)) <= 0.0 or str(c.get("state", "")) == "dead" or c.get("ally", false):
				continue
			if str(c.get("kind", "")) in ["rabbit", "spirit_rabbit", "forest_pheasant"]:
				continue
			var d: float = world.distance(puppet.position, c.position)
			if d < best_d:
				best_d = d
				target = c
	if not target.is_empty():
		puppet.state = "attack"
		if world.distance(puppet.position, target.position) <= 1.8:
			if float(puppet.get("action_cd", 0.0)) <= 0.0:
				puppet.action_cd = 1.0
				var dmg := float(puppet.get("damage", 14.0))
				target.health = float(target.health) - dmg
				target.hit_flash = 0.2
				var col: String = world.index.collection_of.get(int(target.uid), "")
				if col == "creatures":
					world.Creatures.on_creature_hurt(world, target, owner if not owner.is_empty() else puppet)
					if float(target.health) <= 0.0:
						world.Combat.kill(world, target)
				elif col == "npcs":
					if float(target.health) <= 0.0:
						world.Npcs.kill(world, target)
					else:
						world.touch(int(target.uid))
			return []
		return target.position
	if not owner.is_empty() and world.distance(puppet.position, owner.position) > 2.5:
		puppet.state = "follow"
		return owner.position
	return []
