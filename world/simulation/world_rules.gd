extends RefCounted

static func node(kind: String):
	var ids = {"tree": "pine_tree", "bamboo": "bamboo_tree", "twig_bush": "twigs", "berry_bush": "fruit_bush", "spirit_rock": "rock"}
	var path = "res://data/nodes/" + str(ids.get(kind, kind)) + ".tres"
	return load(path) if ResourceLoader.exists(path) else null

static func creature(kind: String):
	var ids = {"rabbit": "spirit_rabbit", "monkey": "spirit_monkey"}
	return load("res://data/creatures/" + str(ids.get(kind, kind)) + ".tres")

static func drops(world, entries: Array, position: Array) -> void:
	for entry in entries:
		if entry.item != null and world.rng.randf() <= entry.chance:
			world.drop_item(str(entry.item.id), world.rng.randi_range(entry.min_count, entry.max_count), position)
const NODE_KINDS = ["tree", "bamboo", "rock", "spirit_rock", "berry_bush", "grass", "twig_bush", "herb"]
