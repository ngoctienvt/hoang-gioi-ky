extends GutTest


func test_layout_determinism_and_bamboo_near_spawn() -> void:
	var w1 := GameWorld.new()
	w1.initialize(12345, {})
	var w2 := GameWorld.new()
	w2.initialize(12345, {})
	var w3 := GameWorld.new()
	w3.initialize(99999, {})

	assert_eq(w1.state.regions.size(), 6)
	for i in 6:
		assert_eq(w1.state.regions[i].biome, w2.state.regions[i].biome)

	var differs := false
	for i in 6:
		if w1.state.regions[i].biome != w3.state.regions[i].biome:
			differs = true
			break
	assert_true(differs, "Different seeds should produce different biome layouts")

	var spawn_biome := w1.biome_at([0.0, 0.0, 0.0])
	assert_eq(spawn_biome, "bamboo_forest", "Spawn should be in or adjacent to bamboo_forest")


func test_all_biomes_have_5_layers_spring_and_teleport() -> void:
	var world := GameWorld.new()
	world.initialize(54321, {})

	var expected_springs := {
		"bamboo_forest": "thanh_moc",
		"nether_swamp": "u_minh",
		"crimson_volcano": "xich_viem",
		"thunder_gorge": "loi_tri",
		"frost_peaks": "huyen_bang",
		"ancient_ruins": "co_van",
	}

	var springs_by_biome := {}
	var teleports_by_biome := {}
	var layers_by_biome := {}

	for node in world.state.nodes:
		var bid := str(node.get("biome", ""))
		if node.kind == "spring":
			springs_by_biome[bid] = springs_by_biome.get(bid, 0) + 1
			assert_eq(str(node.get("water_type", "")), expected_springs[bid])
		elif node.kind == "teleport_array":
			teleports_by_biome[bid] = teleports_by_biome.get(bid, 0) + 1
		var layer := str(node.get("layer", ""))
		if not layer.is_empty():
			if not layers_by_biome.has(bid):
				layers_by_biome[bid] = {}
			layers_by_biome[bid][layer] = true

	for bid in expected_springs:
		assert_eq(springs_by_biome.get(bid, 0), 1, "Biome %s must have 1 spring" % bid)
		assert_eq(teleports_by_biome.get(bid, 0), 1, "Biome %s must have 1 teleport_array" % bid)
		for req_layer in ["food", "wood", "stone", "misc", "den"]:
			assert_true(layers_by_biome.get(bid, {}).has(req_layer), "Biome %s missing layer %s" % [bid, req_layer])
