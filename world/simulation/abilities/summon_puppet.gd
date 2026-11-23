extends RefCounted

const PuppeteerCraft = preload("res://world/simulation/traits/puppeteer_craft.gd")


static func execute(world, player: Dictionary, _args: Dictionary, _def) -> bool:
	var peer_id := -int(player.uid)
	if PuppeteerCraft.guard_puppets(world, peer_id).size() >= 2:
		return false
	var limit: float = world.map_half() - 1.0
	var pos := [
		clampf(float(player.position[0]) + 1.2, -limit, limit),
		0.0,
		clampf(float(player.position[2]), -limit, limit),
	]
	world.Puppets.spawn_guard_puppet(world, pos, peer_id)
	return true
