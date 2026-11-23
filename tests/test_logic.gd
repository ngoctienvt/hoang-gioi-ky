extends GutTest

func test_inventory_stack_split_and_reject_remove() -> void:
	var inv = InventoryComponent.new()
	assert_eq(inv.add_item("twig", 45), 0)
	assert_eq(inv.slots[0].count, 40)
	assert_eq(inv.slots[1].count, 5)
	assert_true(inv.split_stack(0, 2, 10))
	assert_eq(inv.count_item("twig"), 45)
	assert_false(inv.remove_item("twig", 46))
	assert_eq(inv.count_item("twig"), 45)

func test_transferred_items_merge_but_different_expiry_does_not() -> void:
	var inv = InventoryComponent.new()
	inv.add_item("twig", 39)
	inv.add_item("stone", 560)
	assert_eq(inv.add_item("twig", 1, {"id": "twig", "count": 10, "durability": 0}), 0)
	assert_eq(inv.count_item("twig"), 40)
	var water = InventoryComponent.new()
	water.add_item("spirit_water", 1, {"expires": 100.0})
	water.add_item("spirit_water", 1, {"expires": 200.0})
	assert_eq(water.slots[0].count, 1)
	assert_eq(water.slots[1].count, 1)

func test_full_inventory_craft_rolls_back() -> void:
	var inv = InventoryComponent.new()
	inv.add_item("twig", 40)
	inv.add_item("flint", 40)
	inv.add_item("stone", 520)
	var before = inv.to_dict()
	assert_false(inv.craft(RecipeDB.recipes.flint_axe, 0))
	assert_eq(inv.to_dict(), before)

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
