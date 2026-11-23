extends RefCounted


static func tick(world, creature: Dictionary, _definition, _ctx: Dictionary, delta: float) -> void:
	world.HeartDemon.tick_creature(world, creature, delta, 1.0)
