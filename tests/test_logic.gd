extends GutTest

func test_inventory_stack_split_and_reject_remove() -> void:
	var inv = InventoryComponent.new()
	assert_eq(inv.slots.size(), 30)
	assert_eq(inv.add_item("twig", 105), 0)
	assert_eq(inv.slots[0].count, 99)
	assert_eq(inv.slots[1].count, 6)
	assert_true(inv.split_stack(0, 2, 10))
	assert_eq(inv.count_item("twig"), 105)
	assert_false(inv.remove_item("twig", 106))
	assert_eq(inv.count_item("twig"), 105)

func test_transferred_items_merge_but_different_expiry_does_not() -> void:
	var inv = InventoryComponent.new()
	inv.add_item("twig", 98)
	inv.add_item("stone", 2871)
	assert_eq(inv.add_item("twig", 1, {"id": "twig", "count": 10, "durability": 0}), 0)
	assert_eq(inv.count_item("twig"), 99)
	var water = InventoryComponent.new()
	water.add_item("spirit_water", 1, {"expires": 100.0})
	water.add_item("spirit_water", 1, {"expires": 200.0})
	assert_eq(water.slots[0].count, 1)
	assert_eq(water.slots[1].count, 1)

func test_full_inventory_craft_rolls_back() -> void:
	var inv = InventoryComponent.new()
	inv.add_item("twig", 99)
	inv.add_item("flint", 99)
	inv.add_item("stone", 2772)
	var before = inv.to_dict()
	assert_false(inv.craft(RecipeDB.recipes.flint_axe, 0))
	assert_eq(inv.to_dict(), before)

func test_perishable_items_stack_with_weighted_freshness_up_to_99() -> void:
	var inv = InventoryComponent.new()
	assert_eq(inv.add_item("mushroom", 60, {"freshness": 1.0, "_f": 1.0}), 0)
	assert_eq(inv.add_item("mushroom", 50, {"freshness": 0.5, "_f": 0.5}), 0)
	assert_eq(inv.slots[0].count, 99)
	assert_eq(inv.slots[1].count, 11)
	var expected_f := (60.0 * 1.0 + 39.0 * 0.5) / 99.0
	assert_almost_eq(float(inv.slots[0].get("_f", 0.0)), expected_f, 0.001)

func test_merge_or_swap_slots_and_world_move_slot() -> void:
	var inv = InventoryComponent.new()
	inv.slots[0] = {"id": "twig", "count": 60, "durability": 0}
	inv.slots[1] = {"id": "twig", "count": 50, "durability": 0}
	inv.slots[2] = {"id": "stone", "count": 5, "durability": 0}
	assert_true(inv.merge_or_swap_slots(1, 0))
	assert_eq(inv.slots[0].count, 99)
	assert_eq(inv.slots[1].count, 11)
	assert_true(inv.merge_or_swap_slots(0, 2))
	assert_eq(inv.slots[0].id, "stone")
	assert_eq(inv.slots[2].id, "twig")

	var world = GameWorld.new()
	world.initialize(123, {"all_dead": "continue"})
	world.clear_entities()
	world.add_player(1, "Host")
	var p: Dictionary = world.state.players["1"]
	var p_inv = world.inventory(p)
	p_inv.slots[0] = {"id": "mushroom", "count": 60, "durability": 0, "freshness": 1.0, "_f": 1.0}
	p_inv.slots[1] = {"id": "mushroom", "count": 50, "durability": 0, "freshness": 0.5, "_f": 0.5}
	p.inventory = p_inv.to_dict()
	assert_true(world.action(1, "move_slot", {"from": 1, "to": 0}))
	assert_eq(p.inventory.slots[0].count, 99)
	assert_eq(p.inventory.slots[1].count, 11)

func test_restore_upgrades_legacy_15_slot_inventories_to_30() -> void:
	var world = GameWorld.new()
	world.initialize(321, {"all_dead": "continue"})
	world.clear_entities()
	world.add_player(1, "Legacy")
	var legacy_slots: Array = []
	legacy_slots.resize(15)
	for i in 15:
		legacy_slots[i] = {}
	legacy_slots[0] = {"id": "twig", "count": 12, "durability": 0}
	world.state.players["1"].inventory.slots = legacy_slots.duplicate(true)
	var chest = world.entity("chest", [1.0, 0.0, 0.0])
	chest.merge({"health": 200.0, "fuel": 0.0, "ingredients": [], "solvent": "", "remaining": 0.0, "output": "", "pending": "", "slots": legacy_slots.duplicate(true), "crop": "", "growth": 0.0})
	world.add_entity("structures", chest)

	var snap = world.snapshot()
	var restored = GameWorld.new()
	restored.restore(snap)
	restored.add_player(2, "Legacy")
	var rp = restored.state.players["2"]
	assert_eq(rp.inventory.slots.size(), 30)
	assert_eq(rp.inventory.slots[0].count, 12)
	assert_eq(restored.state.structures[0].slots.size(), 30)
	assert_eq(restored.state.structures[0].slots[0].count, 12)

func test_crafting_tier_and_durability() -> void:
	var inv = InventoryComponent.new()
	inv.add_item("twig", 4)
	inv.add_item("flint", 4)
	assert_false(inv.craft(RecipeDB.recipes.shovel, 0))
	assert_true(inv.craft(RecipeDB.recipes.flint_axe, 0))
	for i in inv.slots.size():
		if inv.slots[i].get("id", "") == "flint_axe":
			assert_true(inv.use_durability(i, 80))
	assert_eq(inv.count_item("flint_axe"), 0)

func test_inventory_roundtrip_validates_input() -> void:
	var inv = InventoryComponent.new()
	inv.add_item("flint_axe", 1, {"durability": 7})
	var restored = InventoryComponent.new()
	restored.from_dict(inv.to_dict())
	assert_eq(restored.to_dict(), inv.to_dict())
	restored.from_dict({"slots": [{"id": "unknown", "count": 5}]})
	assert_eq(restored.slots[0], {})

func test_tag_matching_and_fallback() -> void:
	assert_eq(RecipeDB.match_recipe(["spirit_fruit", "spirit_fruit", "twig", "twig"], "cooking").result, "fruit_soup")
	assert_eq(RecipeDB.match_recipe(["spirit_fruit", "spirit_fruit", "spirit_fruit", "twig"], "cooking").result, "fruit_salad")
	assert_eq(RecipeDB.match_recipe(["wild_root", "wild_root", "wild_root", "meat"], "cooking").result, "charred_food")
	assert_eq(RecipeDB.match_recipe(["twig", "twig", "twig", "twig"], "cooking").result, "charred_food")
	assert_eq(RecipeDB.match_recipe(["missing", "twig", "twig", "twig"], "cooking"), {})

func test_alchemy_success_solvent_and_failure() -> void:
	var ids = ["herb", "herb", "twig", "twig"]
	assert_true(RecipeDB.resolve_alchemy(ids, 0.1).success)
	assert_eq(RecipeDB.resolve_alchemy(ids, 0.99).result, "waste_pill")
	assert_almost_eq(RecipeDB.alchemy_chance("blood_pill", 0, "spirit_water"), 0.9, 0.0001)

func test_clock_boundaries_and_serialization() -> void:
	var old = GameClock.to_dict()
	GameClock.from_dict({})
	assert_eq(GameClock.phase(), "day")
	GameClock.advance(240.0)
	assert_eq(GameClock.phase(), "dusk")
	GameClock.advance(180.0)
	assert_eq(GameClock.phase(), "night")
	GameClock.advance(60.0)
	assert_eq(GameClock.day, 2)
	assert_eq(GameClock.phase(), "day")
	GameClock.from_dict(old)

func test_survival_darkness_light_hunger_poison() -> void:
	var stats = SurvivalStats.new()
	stats.tick(5.0, true, false)
	assert_lt(stats.health, 150.0)
	var health = stats.health
	stats.tick(10.0, true, true)
	assert_eq(stats.health, health)
	stats.stamina = 0.0
	stats.tick(1.0, false, false)
	assert_lt(stats.health, health)
	for i in 3:
		stats.eat(ItemDB.get_item("blood_pill"))
	assert_gt(stats.poison, 50.0)
	stats.revive()
	stats.revive()
	stats.revive()
	assert_eq(stats.max_health, 75.0)

func test_save_roundtrip_and_reject_path_traversal() -> void:
	var state = {"seed": 42, "players": {"test": {"health": 70}}, "clock": {"day": 2}}
	assert_eq(SaveManager.save_world(state, "regression_test"), OK)
	assert_eq(SaveManager.load_world("regression_test"), state)
	assert_eq(SaveManager.load_world("../outside"), {})
	assert_false(SaveManager._valid_slot("../outside"))
	DirAccess.remove_absolute(SaveManager.SAVE_DIR + "regression_test.json")

func test_content_resources_load() -> void:
	for dir in ["nodes", "creatures"]:
		for file in DirAccess.get_files_at("res://data/" + dir):
			if file.ends_with(".tres"):
				assert_not_null(load("res://data/" + dir + "/" + file))
