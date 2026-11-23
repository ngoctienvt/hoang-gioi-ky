extends RefCounted

const BiomeGenerator = preload("res://world/simulation/world_biome_generator.gd")


static func generate(world) -> void:
	BiomeGenerator.generate(world)
