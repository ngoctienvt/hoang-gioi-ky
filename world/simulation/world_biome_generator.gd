extends RefCounted

const Rules = preload("res://world/simulation/world_rules.gd")
const Layout = preload("res://world/simulation/world_layout.gd")
const TRANSITION_BAND := 4.0
const DEN_CREATURE_MAP := {
	"pheasant_den": {"kind": "forest_pheasant", "count": 3},
	"leech_den": {"kind": "spirit_leech", "count": 3},
	"crow_den": {"kind": "carrion_crow", "count": 2},
	"ancient_grave": {"kind": "jiangshi", "count": 2},
	"lava_lizard_den": {"kind": "lava_lizard", "count": 2},
	"fire_bird_nest": {"kind": "fire_bird", "count": 2},
	"thunder_beast_den": {"kind": "thunder_beast", "count": 2},
	"golem_pillar": {"kind": "stone_golem", "count": 1},
	"ice_wolf_den": {"kind": "ice_wolf", "count": 3},
	"snow_bear_den": {"kind": "snow_bear", "count": 1},
	"thick_fur_den": {"kind": "thick_fur_beast", "count": 3},
	"construct_den": {"kind": "construct_beast", "count": 2},
	"wraith_shrine": {"kind": "ruin_wraith", "count": 2},
}


static func generate(world) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(world.state.seed) + 104729
	var map_size: float = world.map_size()
	var regions: Array = Layout.generate(int(world.state.seed), map_size)
	world.state.regions = regions
	world.state.teleports = []

	var biome_defs: Dictionary = {}
	for bid in Layout.BIOME_IDS:
		var path := "res://data/biomes/%s.tres" % bid
		if ResourceLoader.exists(path):
			biome_defs[bid] = load(path)

	for region in regions:
		var bid: String = str(region.biome)
		var bdef: BiomeDef = biome_defs.get(bid)
		if bdef == null:
			continue
		var cx := float(region.center[0])
		var cz := float(region.center[2])

		# 1. Spring near center offset
		var spring_pos := [cx + 6.0, 0.0, cz + 4.0]
		var spring: Dictionary = world.entity("spring", spring_pos)
		spring.merge({"water_type": String(bdef.water_type), "biome": bid})
		world.add_entity("nodes", spring)

		# 2. Teleport array near region center
		var tp_pos := [cx - 5.0, 0.0, cz - 4.0]
		var tp: Dictionary = world.entity("teleport_array", tp_pos)
		tp.merge({"state": "dormant", "biome": bid})
		world.add_entity("nodes", tp)
		world.state.teleports.append({
			"uid": tp.uid,
			"biome": bid,
			"state": "dormant",
			"position": tp_pos.duplicate(),
		})

		# 3. Required set pieces (5 layers)
		var placed_count := 0
		for piece in bdef.required_pieces:
			if piece == null:
				continue
			var pos := _find_piece_spot(world, rng, region, piece.radius, 32)
			if not pos.is_empty():
				_spawn_set_piece(world, rng, piece, pos, bid)
				placed_count += 1

		# 4. Optional set pieces up to biome density
		var weights := bdef.optional_weights
		var attempts := 0
		while placed_count < bdef.density and attempts < bdef.density * 4 and not bdef.optional_pieces.is_empty():
			attempts += 1
			var idx := rng.rand_weighted(weights) if weights.size() == bdef.optional_pieces.size() else rng.randi_range(0, bdef.optional_pieces.size() - 1)
			var piece: SetPieceDef = bdef.optional_pieces[idx]
			if piece == null:
				continue
			var pos := _find_piece_spot(world, rng, region, piece.radius, 12)
			if not pos.is_empty():
				_spawn_set_piece(world, rng, piece, pos, bid)
				placed_count += 1

		# 5. Biome-specific non-seasonal environmental nodes
		if bid == "nether_swamp":
			for _m in 6:
				var mpos := _find_piece_spot(world, rng, region, 2.5, 16)
				if not mpos.is_empty():
					var mud: Dictionary = world.entity("mud", mpos)
					mud.merge({"biome": bid, "non_blocking": true})
					world.add_entity("nodes", mud)
		elif bid == "ancient_ruins":
			for _t in 6:
				var tpos := _find_piece_spot(world, rng, region, 2.5, 16)
				if not tpos.is_empty():
					var trap: Dictionary = world.entity("floor_trap", tpos)
					trap.merge({"biome": bid, "cooldown": 0.0, "non_blocking": true})
					world.add_entity("nodes", trap)
			for _s in 2:
				var spos := _random_in_region(rng, region, 12.0)
				if world.index.entities_near(spos, 2.5).is_empty():
					var seal: Dictionary = world.entity("seal_stone", spos)
					seal.merge({"biome": bid, "stage": 0, "hits": 0, "depleted": false})
					world.add_entity("nodes", seal)
		if bid in ["ancient_ruins", "crimson_volcano"]:
			for _o in 2:
				var opos := _random_in_region(rng, region, 12.0)
				if world.index.entities_near(opos, 2.5).is_empty():
					var ore: Dictionary = world.entity("sect_ore", opos)
					ore.merge({"biome": bid, "stage": 0, "hits": 0, "depleted": false})
					world.add_entity("nodes", ore)
		var apos := [cx + 2.0, 0.0, cz - 7.0]
		if world.index.entities_near(apos, 2.0).is_empty():
			var altar_node: Dictionary = world.entity("altar", apos)
			altar_node.merge({"biome": bid})
			world.add_entity("nodes", altar_node)

	# 6. Ancient stone road (ruin_path) connecting adjacent region centers across transition bands
	for region in regions:
		var c1: Array = region.center
		for other in regions:
			if int(other.index) <= int(region.index):
				continue
			var dr := absi(int(other.row) - int(region.row))
			var dc := absi(int(other.col) - int(region.col))
			if dr + dc == 1:
				var c2: Array = other.center
				var steps := 12
				for s in range(1, steps):
					var t := float(s) / float(steps)
					var p := [lerpf(float(c1[0]), float(c2[0]), t), 0.0, lerpf(float(c1[2]), float(c2[2]), t)]
					if world.distance(p, [0, 0, 0]) < 2.5:
						continue
					var road: Dictionary = world.entity("ruin_path", p)
					road.merge({"non_blocking": true, "biome": Layout.biome_at(regions, p)})
					world.add_entity("nodes", road)

	# 7. Starter ground drops near spawn [0, 0, 0]
	for index in range(48):
		var id: String = ["flint", "twig", "grass", "mushroom", "wild_root"][index % 5]
		world.drop_item(id, 1, [rng.randf_range(-12, 12), 0.0, rng.randf_range(-12, 12)])

	# 8. Starter creatures near spawn / bamboo_forest
	var bamboo_region := {}
	for r in regions:
		if r.biome == "bamboo_forest":
			bamboo_region = r
			break
	var bc: Array = bamboo_region.get("center", [0.0, 0.0, -30.0])
	for group in [
		{"kind": "rabbit", "home": [float(bc[0]) - 8.0, 0.0, float(bc[2]) + 8.0], "count": 4},
		{"kind": "wolf", "home": [float(bc[0]) - 18.0, 0.0, float(bc[2]) - 14.0], "count": 3},
		{"kind": "monkey", "home": [float(bc[0]) + 10.0, 0.0, float(bc[2]) - 10.0], "count": 3},
	]:
		var den: Dictionary = world.entity(group.kind + "_den", group.home)
		den.merge({"biome": "bamboo_forest", "layer": "den"})
		world.add_entity("nodes", den)
		for _i in range(group.count):
			var cpos := [float(group.home[0]) + rng.randf_range(-2, 2), 0.0, float(group.home[2]) + rng.randf_range(-2, 2)]
			var creature: Dictionary = world.entity(group.kind, cpos)
			creature.merge({
				"health": Rules.creature(group.kind).max_health,
				"home": group.home.duplicate(),
				"state": "idle",
				"behavior_state": "idle",
				"effects": {},
				"cooldown": 0.0,
				"respawn": 0.0,
				"stolen": [],
				"biome": "bamboo_forest",
			})
			world.add_entity("creatures", creature)


static func _random_in_region(rng: RandomNumberGenerator, region: Dictionary, margin: float) -> Array:
	var x := rng.randf_range(float(region.min_x) + margin, float(region.max_x) - margin)
	var z := rng.randf_range(float(region.min_z) + margin, float(region.max_z) - margin)
	return [x, 0.0, z]


static func _find_piece_spot(world, rng: RandomNumberGenerator, region: Dictionary, radius: float, max_tries: int) -> Array:
	var half: float = world.map_half() - maxf(TRANSITION_BAND, radius + 2.0)
	var cx := float(region.center[0])
	var cz := float(region.center[2])
	for _i in max_tries * 3:
		var x := clampf(cx + rng.randf_range(-72.0, 72.0), -half, half)
		var z := clampf(cz + rng.randf_range(-72.0, 72.0), -half, half)
		var pos := [x, 0.0, z]
		if Layout.biome_at(world.state.regions, pos) != str(region.biome):
			continue
		if world.distance(pos, [0.0, 0.0, 0.0]) < 4.5:
			continue
		if world.index.entities_near(pos, radius + 1.5, "nodes").is_empty():
			return pos
	return []


static func _spawn_set_piece(world, rng: RandomNumberGenerator, piece: SetPieceDef, origin: Array, biome_id: String) -> void:
	for entry in piece.entries:
		var kind: String = str(entry.get("kind", ""))
		if kind.is_empty():
			continue
		var offset: Vector2 = entry.get("offset", Vector2.ZERO)
		var jitter: float = float(entry.get("jitter", 0.4))
		var pos := [
			float(origin[0]) + offset.x + rng.randf_range(-jitter, jitter),
			0.0,
			float(origin[2]) + offset.y + rng.randf_range(-jitter, jitter),
		]
		var node: Dictionary = world.entity(kind, pos)
		node.merge({
			"stage": 0,
			"hits": 0,
			"regrow": 0.0,
			"age": 0.0,
			"depleted": false,
			"biome": biome_id,
			"layer": String(piece.layer_tag),
		})
		if kind == "floor_trap":
			node["cooldown"] = 0.0
			node["non_blocking"] = true
		elif kind == "mud":
			node["non_blocking"] = true
		world.add_entity("nodes", node)
		if DEN_CREATURE_MAP.has(kind):
			var info: Dictionary = DEN_CREATURE_MAP[kind]
			var cdef = Rules.creature(str(info.kind))
			if cdef != null:
				for _c in int(info.count):
					var cpos := [pos[0] + rng.randf_range(-1.5, 1.5), 0.0, pos[2] + rng.randf_range(-1.5, 1.5)]
					var creature: Dictionary = world.entity(str(info.kind), cpos)
					creature.merge({
						"health": cdef.max_health,
						"home": pos.duplicate(),
						"state": "idle",
						"behavior_state": "idle",
						"effects": {},
						"cooldown": 0.0,
						"respawn": 0.0,
						"stolen": [],
						"biome": biome_id,
					})
					world.add_entity("creatures", creature)
