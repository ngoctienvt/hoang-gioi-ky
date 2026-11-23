extends GutTest
## Resource depletion, creature AI gating, predation karma, heart demon pursuit and leech drain.

const Season = preload("res://world/simulation/world_season.gd")


func _world(seed_value: int = 31) -> GameWorld:
	var world := GameWorld.new()
	world.initialize(seed_value, {"day_length": 480.0})
	world.clear_entities()
	world.add_player(1, "Tester")
	world.state.players["1"].position = [0.0, 0.0, 0.0]
	return world


func _give(world, item_id: String) -> void:
	var player: Dictionary = world.state.players["1"]
	var inv = world.inventory(player)
	inv.add_item(item_id, 1)
	player.inventory = inv.to_dict()


func _node(world, kind: String, pos: Array) -> Dictionary:
	var node: Dictionary = world.entity(kind, pos)
	node.merge({"stage": 0, "hits": 0, "regrow": 0.0, "depleted": false})
	world.add_entity("nodes", node)
	return node


func _work_until_done(world, node: Dictionary, max_hits: int) -> int:
	var accepted := 0
	for _i in max_hits:
		world.state.players["1"].work_cd = 0.0
		if world.action(1, "work", {"uid": node.uid, "auto_equip": true}):
			accepted += 1
	return accepted


func test_resource_non_regrowing_tree_is_gone_after_felling() -> void:
	# Arrange: a snow pine (3 hits, never regrows, no stump).
	var world := _world()
	_give(world, "flint_axe")
	var pine := _node(world, "snow_pine", [1.0, 0.0, 0.0])

	# Act: keep swinging far past the 3 hits it takes.
	var accepted := _work_until_done(world, pine, 12)

	# Assert: it yields its wood once and then is gone instead of yielding forever.
	assert_eq(accepted, 3, "only the hits that fell the tree are accepted")
	assert_true(world.index.find(int(pine.uid)).is_empty(), "felled snow pine is removed")


func test_resource_forest_tree_leaves_stump_dug_with_shovel_only() -> void:
	# Arrange
	var world := _world()
	_give(world, "flint_axe")
	var tree := _node(world, "tree", [1.0, 0.0, 0.0])

	# Act
	var accepted := _work_until_done(world, tree, 30)

	# Assert: the stump stays and an axe cannot harvest it again.
	assert_eq(accepted, 15, "felling takes the defined 15 hits, nothing more")
	assert_false(world.index.find(int(tree.uid)).is_empty(), "the stump remains")
	assert_true(bool(tree.depleted))


func test_resource_flint_picked_up_once() -> void:
	var world := _world()
	var flint := _node(world, "flint", [1.0, 0.0, 0.0])
	var accepted := _work_until_done(world, flint, 6)
	assert_eq(accepted, 1)
	assert_true(world.index.find(int(flint.uid)).is_empty(), "flint is gone once taken")


func test_creature_ai_frozen_when_no_player_is_connected() -> void:
	# Arrange: a rabbit right next to where the only player was before leaving.
	var world := _world()
	var rabbit: Dictionary = world.entity("rabbit", [3.0, 0.0, 0.0])
	rabbit.merge({"health": 20.0, "home": [3.0, 0.0, 0.0], "state": "idle", "cooldown": 0.0, "respawn": 0.0, "stolen": [], "effects": {}})
	world.add_entity("creatures", rabbit)
	world.remove_player(1)
	var before: Array = rabbit.position.duplicate()

	# Act
	for _i in 20:
		world.step(0.5)

	# Assert: an idle rabbit would wander around its home if it were ticked.
	assert_eq(rabbit.position, before, "nobody in the world, no AI")


func test_creature_far_wanderer_does_not_tick_but_near_one_does() -> void:
	# Arrange: two idle rabbits, one in reach of the player and one 200 m away.
	var world := _world()
	var near_rabbit: Dictionary = world.entity("rabbit", [5.0, 0.0, 0.0])
	var far_rabbit: Dictionary = world.entity("rabbit", [200.0, 0.0, 0.0])
	for r in [near_rabbit, far_rabbit]:
		r.merge({"health": 20.0, "home": r.position.duplicate(), "state": "idle", "cooldown": 0.0, "respawn": 0.0, "stolen": [], "effects": {}})
		world.add_entity("creatures", r)
	var near_before: Array = near_rabbit.position.duplicate()
	var far_before: Array = far_rabbit.position.duplicate()

	# Act
	for _i in 20:
		world.step(0.5)

	# Assert
	assert_ne(near_rabbit.position, near_before, "the near rabbit wanders")
	assert_eq(far_rabbit.position, far_before, "the far rabbit is asleep")


func test_creature_wolf_killing_rabbit_adds_no_sin() -> void:
	# Arrange: dusk (wolves awake, rabbits not yet burrowed), a weak rabbit beside a wolf, the player
	# in range for AI but beyond the wolf's notice.
	var world := _world()
	var step := world.day_length() / 16.0
	while str(world.state.clock.get("phase", "")) != "dusk":
		world.state.clock.elapsed += step
		Season.update_clock(world)
	world.state.players["1"].position = [40.0, 0.0, 0.0]
	var rabbit: Dictionary = world.entity("rabbit", [0.6, 0.0, 0.0])
	rabbit.merge({"health": 1.0, "home": [0.6, 0.0, 0.0], "state": "idle", "cooldown": 0.0, "respawn": 0.0, "stolen": [], "effects": {}})
	var wolf: Dictionary = world.entity("wolf", [0.0, 0.0, 0.0])
	wolf.merge({"health": 80.0, "home": [0.0, 0.0, 0.0], "state": "idle", "cooldown": 0.0, "respawn": 0.0, "stolen": [], "effects": {}})
	# The wolf acts first in the step, before the rabbit can bolt.
	world.add_entity("creatures", wolf)
	world.add_entity("creatures", rabbit)
	var sin_before := float(world.Karma.ensure_state(world).get("sin", 0.0))

	# Act
	for _i in 4:
		world.step(0.25)

	# Assert
	assert_lte(float(rabbit.health), 0.0, "the wolf killed the rabbit")
	assert_eq(float(world.state.karma.get("sin", 0.0)), sin_before, "predation is not the players' sin")


func test_heart_demon_chases_its_owner() -> void:
	# Arrange: a shaken Dao Heart summons a demon.
	var world := _world()
	var player: Dictionary = world.state.players["1"]
	player.stats.dao = 20.0
	world.step(0.1)
	var demon: Dictionary = {}
	for c in world.state.creatures:
		if str(c.kind) == "heart_demon":
			demon = c
	assert_false(demon.is_empty(), "a demon appears")
	var start := float(world.distance(demon.position, player.position))

	# Act
	for _i in 4:
		player.stats.dao = 20.0
		world.step(0.25)

	# Assert
	assert_lt(float(world.distance(demon.position, player.position)), start, "the demon closes in, it does not flee")


func test_leech_drain_is_once_per_second_and_does_not_wear_armour() -> void:
	# Arrange: a player in body armour with a leech already latched on.
	var world := _world()
	var player: Dictionary = world.state.players["1"]
	player.inventory.equipment["body"] = {"id": "fur_coat", "count": 1, "durability": 50}
	var leech: Dictionary = world.entity("spirit_leech", [0.5, 0.0, 0.0])
	leech.merge({"health": 45.0, "home": [0.0, 0.0, 0.0], "state": "special", "cooldown": 0.0, "respawn": 0.0, "stolen": [], "effects": {}, "attached_peer": 1})
	world.add_entity("creatures", leech)
	var hp_before := float(player.stats.health)

	# Act: 2 seconds in 0.1 s frames.
	for _i in 20:
		world.step(0.1)

	# Assert
	assert_lt(float(player.stats.health), hp_before, "the leech drains")
	assert_eq(int(player.inventory.equipment.body.durability), 50, "draining does not wear the armour")
