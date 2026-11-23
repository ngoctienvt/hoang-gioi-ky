extends RefCounted


static func execute(_world, player: Dictionary, _args: Dictionary, _def) -> bool:
	player["sense_time"] = 8.0
	return true
