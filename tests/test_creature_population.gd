extends GutTest


func test_all_biomes_have_at_least_two_species_and_distant_ai_sleeps() -> void:
	var world := GameWorld.new()
	world.initialize(2026, {})

	var by_biome := {}
	for c in world.state.creatures:
		var b := str(c.get("biome", world.biome_at(c.position)))
		if not by_biome.has(b):
			by_biome[b] = {}
		by_biome[b][str(c.kind)] = true

	for b in ["bamboo_forest", "nether_swamp", "crimson_volcano", "thunder_gorge", "frost_peaks", "ancient_ruins"]:
		assert_true(by_biome.has(b), "Biome %s must have creatures" % b)
		assert_gte(by_biome[b].size(), 2, "Biome %s must have at least 2 creature species" % b)

	# Verify creatures outside 3 chunks of any player do not tick
	world.add_player(1, "Tester")
	world.state.players["1"].position = [0.0, 0.0, 0.0]
	var far_creature := {}
	for c in world.state.creatures:
		if world.distance(c.position, [0.0, 0.0, 0.0]) > 120.0:
			far_creature = c
			break
	assert_false(far_creature.is_empty())
	var pos_before: Array = far_creature.position.duplicate()
	for _i in 10:
		world.step(0.5)
	assert_eq(far_creature.position, pos_before, "Distant creature (>3 chunks) should not tick")
