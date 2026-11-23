extends RefCounted

const BASE_MAX_HEALTH := 150.0
## Spirit beings (linh thể): hidden and immune to blows unless the player can see spirits
## (U Minh tempered weapon, Phá Hồn / spirit sight, a shaken Dao Heart, Boundary Dao).
## Days an ice block (băng khối) lasts before it has melted away (summer melts it twice as fast).
const ICE_BLOCK_MELT_DAYS := 3.0
## Fuel burn multipliers for open fires (campfire, firepit) in bad weather.
const RAIN_FIRE_FUEL_RATE := 1.5
const STORM_FIRE_FUEL_RATE := 2.0
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


## Definitions are looked up every simulation step for every entity, so they are cached by kind
## (null included, for kinds without a definition).
static var _node_defs: Dictionary = {}
static var _creature_defs: Dictionary = {}


static func node(kind: String):
	if not _node_defs.has(kind):
		var path := "res://data/nodes/" + str(NODE_ALIASES.get(kind, kind)) + ".tres"
		_node_defs[kind] = load(path) if ResourceLoader.exists(path) else null
	return _node_defs[kind]


static func creature(kind: String):
	if not _creature_defs.has(kind):
		var path := "res://data/creatures/" + str(CREATURE_ALIASES.get(kind, kind)) + ".tres"
		_creature_defs[kind] = load(path) if ResourceLoader.exists(path) else null
	return _creature_defs[kind]


## Spirits (CreatureDef.spirit) can only be seen and struck with spirit sight.
static func is_spirit(kind: String) -> bool:
	var definition = creature(kind)
	return definition != null and bool(definition.spirit)


static func drops(world, entries: Array, position: Array) -> void:
	for entry in entries:
		if entry.item != null and world.rng.randf() <= entry.chance:
			world.drop_item(str(entry.item.id), world.rng.randi_range(entry.min_count, entry.max_count), position)
