extends RefCounted
const Rules = preload("res://world/simulation/world_rules.gd")

static func generate(world) -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = world.state.seed
	var regions = [{"center": [-20, -18], "biome": "forest", "kinds": ["tree", "tree", "berry_bush", "herb"]}, {"center": [18, -18], "biome": "bamboo_forest", "kinds": ["bamboo", "bamboo", "herb", "twig_bush"]}, {"center": [-18, 18], "biome": "rocks", "kinds": ["rock", "rock", "spirit_rock", "twig_bush"]}, {"center": [0, 0], "biome": "grassland", "kinds": ["grass", "twig_bush", "berry_bush", "grass"]}]
	for region in regions:
		for index in range(36):
			var kind = region.kinds[index % region.kinds.size()]
			var pos = [region.center[0] + (index % 6 - 2.5) * 3 + rng.randf_range(-0.6, 0.6), 0.0, region.center[1] + (index / 6 - 2.5) * 3 + rng.randf_range(-0.6, 0.6)]
			if world.distance(pos, [0, 0, 0]) < 3:
				continue
			var node = world.entity(kind, pos)
			node.merge({"stage": 0, "hits": 0, "regrow": 0.0, "age": 0.0, "depleted": false, "biome": region.biome})
			world.state.nodes.append(node)
	for index in range(64):
		var id = ["flint", "twig", "grass", "mushroom", "wild_root"][index % 5]
		world.drop_item(id, 1, [rng.randf_range(-14, 14), 0.0, rng.randf_range(-14, 14)])
	for index in range(2):
		world.state.nodes.append(world.entity("spring", [18.0 + index * 4, 0.0, 18.0]))
	for group in [{"kind": "rabbit", "home": [-6, 0, 9], "count": 4}, {"kind": "wolf", "home": [-27, 0, -25], "count": 3}, {"kind": "monkey", "home": [-16, 0, -15], "count": 3}]:
		world.state.nodes.append(world.entity(group.kind + "_den", group.home))
		for index in range(group.count):
			var pos = [group.home[0] + rng.randf_range(-2, 2), 0.0, group.home[2] + rng.randf_range(-2, 2)]
			var creature = world.entity(group.kind, pos)
			creature.merge({"health": Rules.creature(group.kind).max_health, "home": group.home.duplicate(), "state": "idle", "cooldown": 0.0, "respawn": 0.0, "stolen": []})
			world.state.creatures.append(creature)
