extends RefCounted

const BASE_MAX_HEALTH := 150.0
const PLAYER_TIMERS := [
	"attack_cd",
	"work_cd",
	"ability_cd",
	"sense_cd",
	"beast_time",
	"sense_time",
	"night_vision",
	"spring_heal",
	"hit_flash",
	"warm_time",
	"cool_time",
	"speed_boost_time",
	"warmer_wear",
]
const NODE_ALIASES := {
	"tree": "pine_tree",
	"bamboo": "bamboo_tree",
	"twig_bush": "twigs",
	"berry_bush": "fruit_bush",
	"spirit_rock": "rock",
}
const CREATURE_ALIASES := {
	"rabbit": "spirit_rabbit",
	"monkey": "spirit_monkey",
}
const NODE_KINDS := ["tree", "bamboo", "rock", "spirit_rock", "berry_bush", "grass", "twig_bush", "herb"]


static func node(kind: String):
	var path := "res://data/nodes/" + str(NODE_ALIASES.get(kind, kind)) + ".tres"
	return load(path) if ResourceLoader.exists(path) else null


static func creature(kind: String):
	var path := "res://data/creatures/" + str(CREATURE_ALIASES.get(kind, kind)) + ".tres"
	return load(path) if ResourceLoader.exists(path) else null


static func drops(world, entries: Array, position: Array) -> void:
	for entry in entries:
		if entry.item != null and world.rng.randf() <= entry.chance:
			world.drop_item(str(entry.item.id), world.rng.randi_range(entry.min_count, entry.max_count), position)
