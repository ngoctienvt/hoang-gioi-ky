extends GutTest


func test_fill_and_drink_all_six_spring_types() -> void:
	var world := GameWorld.new()
	world.initialize(444, {})
	world.clear_entities()
	world.add_player(1, "Tester")
	var player: Dictionary = world.state.players["1"]

	var types := ["thanh_moc", "u_minh", "xich_viem", "loi_tri", "huyen_bang", "co_van"]
	for wtype in types:
		var spring := world.entity("spring", [1.0, 0.0, 0.0])
		spring["water_type"] = wtype
		world.add_entity("nodes", spring)

		var inv = world.inventory(player)
		inv.add_item("water_bottle", 1)
		player.inventory = inv.to_dict()

		assert_true(world.action(1, "water", {"uid": spring.uid, "mode": "fill"}))
		var expected_item: String = "spirit_water_" + str(wtype)
		assert_eq(world.inventory(player).count_item(expected_item), 1, "Expected item %s" % expected_item)

		player.stats.dao = 100.0
		assert_true(world.action(1, "water", {"uid": spring.uid, "mode": "drink"}))
		match wtype:
			"thanh_moc":
				assert_gt(float(player.spring_heal), 0.0)
			"u_minh":
				assert_gt(float(player.sense_time), 0.0)
				assert_lt(float(player.stats.dao), 100.0)
			"xich_viem":
				assert_gt(float(player.warm_time), 0.0)
			"loi_tri":
				assert_gt(float(player.speed_boost_time), 0.0)
			"huyen_bang":
				assert_gt(float(player.cool_time), 0.0)

		world.remove_entity(spring)
		var cleanup_inv = world.inventory(player)
		cleanup_inv.remove_item(expected_item, 1)
		player.inventory = cleanup_inv.to_dict()
