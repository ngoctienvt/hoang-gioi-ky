extends RefCounted
## A heart demon hunts only the player whose Dao Heart summoned it (see world_heart_demon.gd).


static func tick(world, creature: Dictionary, definition: CreatureDef, ctx: Dictionary, _delta: float) -> void:
	world.HeartDemon.tick_creature(world, creature, definition, ctx)
