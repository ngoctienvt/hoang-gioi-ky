extends RefCounted


static func execute(world, player: Dictionary, _args: Dictionary, _def) -> bool:
	player["beast_time"] = 15.0
	world.life.clear_hand(world, player)
	return true
