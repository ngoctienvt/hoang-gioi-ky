extends GutTest
## Forbidden recipes unlock through karma; talismans can fail and only burn the paper.

const Helpers = preload("res://tests/structure_test_helpers.gd")
const PuppeteerCraft = preload("res://world/simulation/traits/puppeteer_craft.gd")


func _world() -> GameWorld:
	var world := GameWorld.new()
	world.initialize(64, {"day_length": 480.0})
	world.clear_entities()
	world.add_player(1, "Crafter")
	world.state.players["1"].position = [0.0, 0.0, 0.0]
	return world


func _give(world, items: Dictionary) -> void:
	var player: Dictionary = world.state.players["1"]
	var inv = world.inventory(player)
	for id in items:
		inv.add_item(str(id), int(items[id]))
	player.inventory = inv.to_dict()


func _count(world, id: String) -> int:
	return world.inventory(world.state.players["1"]).count_item(id)


func test_crafting_forbidden_recipe_needs_the_evil_cultivator_event() -> void:
	# Arrange: a furnace in reach and the ingredients in the bag.
	var world := _world()
	assert_false(Helpers.place(world, 1, "workbench", [0.0, 0.0, -3.0]).is_empty())
	assert_false(Helpers.place(world, 1, "alchemy_furnace", [2.0, 0.0, 0.0]).is_empty())
	_give(world, {"soul_herb": 4, "yin_soul_crystal": 2})

	# Act / Assert: refused while locked.
	assert_false(world.action(1, "craft", {"recipe": "forbidden_conceal_pill"}), "locked before the event")
	var ev: KarmaEventDef = load("res://data/karma/sin_60_evil_recipe.tres")
	world.Karma.Events.execute(world, ev)
	assert_true(world.action(1, "craft", {"recipe": "forbidden_conceal_pill"}), "unlocked after the event")
	assert_eq(_count(world, "conceal_pill"), 2)


func test_crafting_talisman_failure_burns_only_the_paper() -> void:
	# Arrange: a talisman desk and plenty of ingredients; force the roll to fail.
	var world := _world()
	assert_false(Helpers.place(world, 1, "workbench", [0.0, 0.0, -3.0]).is_empty())
	assert_false(Helpers.place(world, 1, "talisman_desk", [2.0, 0.0, 0.0]).is_empty())
	_give(world, {"talisman_paper": 20, "cinnabar": 20, "grass": 40})
	var made := 0
	var failed := 0

	# Act: 20 attempts at 85%.
	for _i in 20:
		var paper_before := _count(world, "talisman_paper")
		var cinnabar_before := _count(world, "cinnabar")
		var bind_before := _count(world, "bind_talisman")
		assert_true(world.action(1, "craft", {"recipe": "bind_talisman"}))
		if _count(world, "bind_talisman") > bind_before:
			made += 1
		else:
			failed += 1
			assert_eq(_count(world, "talisman_paper"), paper_before - 1, "a failure burns the paper")
			assert_eq(_count(world, "cinnabar"), cinnabar_before, "and keeps the cinnabar")

	# Assert
	assert_gt(made, 0)
	assert_gt(failed, 0, "with 20 tries at 85% some fail (seeded rng)")


func test_crafting_puppeteer_talismans_never_fail_at_base_85_percent() -> void:
	var player := {"character": "puppeteer"}
	assert_eq(PuppeteerCraft.talisman_success_chance(player, 0.85), 1.0)
