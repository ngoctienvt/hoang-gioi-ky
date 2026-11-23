extends RefCounted

const Tasks = preload("res://world/simulation/puppet_tasks.gd")
const PuppeteerCraft = preload("res://world/simulation/traits/puppeteer_craft.gd")


static func deploy_from_recipe(world, player: Dictionary, recipe: Dictionary, pos: Array) -> bool:
	var kind := str(recipe.get("result", ""))
	if not kind.begins_with("puppet_"):
		return false
	var inv = world.inventory(player)
	var reqs := PuppeteerCraft.effective_ingredients(player, recipe.resource)
	if not world.craft(inv, recipe, world.tier(player), reqs):
		return false
	inv.remove_item(kind, int(recipe.get("count", 1)))
	player.inventory = inv.to_dict()
	spawn_puppet(world, kind, pos, -int(player.uid))
	world.discover(str(recipe.get("id", kind)))
	return true


static func spawn_puppet(world, kind: String, pos: Array, owner_peer: int = 1) -> Dictionary:
	var task := kind.trim_prefix("puppet_")
	var stake_uid := 0
	var best_d := 8.5
	for s in world.index.entities_near(pos, 8.0, "structures"):
		if s.kind == "stake":
			var d: float = world.distance(pos, s.position)
			if d < best_d:
				best_d = d
				stake_uid = int(s.uid)
	var puppet: Dictionary = world.entity(kind, pos)
	puppet.merge({
		"task": task,
		"stake_uid": stake_uid,
		"home": pos.duplicate(),
		"fuel": world.day_length() * 0.5,
		"health": 120.0,
		"max_health": 120.0,
		"speed": 2.0,
		"state": "idle",
		"carrying": {},
		"owner_peer": owner_peer,
		"action_cd": 0.0,
		"stuck_timer": 0.0,
		"detour_time": 0.0,
		"detour_angle": 0.0,
	})
	world.add_entity("puppets", puppet)
	return puppet


static func spawn_guard_puppet(world, pos: Array, owner_peer: int = 1) -> Dictionary:
	var puppet: Dictionary = world.entity("puppet_guard", pos)
	puppet.merge({
		"task": "guard",
		"stake_uid": 0,
		"home": pos.duplicate(),
		"fuel": 120.0,
		"health": 100.0,
		"max_health": 100.0,
		"speed": 4.2,
		"damage": 14.0,
		"target_uid": 0,
		"state": "idle",
		"carrying": {},
		"owner_peer": owner_peer,
		"action_cd": 0.0,
		"stuck_timer": 0.0,
		"detour_time": 0.0,
		"detour_angle": 0.0,
	})
	world.add_entity("puppets", puppet)
	return puppet


static func damage_puppet(world, puppet: Dictionary, amount: float) -> void:
	if puppet.is_empty():
		return
	puppet.health = float(puppet.get("health", 120.0)) - amount
	if float(puppet.health) <= 0.0:
		var carrying: Dictionary = puppet.get("carrying", {})
		if not carrying.is_empty():
			world.drop_item(str(carrying.id), int(carrying.count), puppet.position, carrying.get("extra", {}))
		world.drop_item("wood", 2, puppet.position)
		world.drop_item("stone", 1, puppet.position)
		world.drop_item("spirit_stone", 1, puppet.position)
		world.remove_entity(puppet)
	else:
		world.touch(int(puppet.uid))


static func step(world, delta: float) -> void:
	for puppet in world.state.get("puppets", []).duplicate():
		if float(puppet.get("health", 0.0)) <= 0.0:
			continue
		puppet.fuel = maxf(0.0, float(puppet.get("fuel", 0.0)) - delta)
		if float(puppet.fuel) <= 0.0:
			if str(puppet.get("task", "")) == "guard":
				world.remove_entity(puppet)
				continue
			if str(puppet.get("state", "")) != "out_of_fuel":
				puppet.state = "out_of_fuel"
				world.touch(int(puppet.uid))
			continue
		Tasks.tick(world, puppet, delta)
