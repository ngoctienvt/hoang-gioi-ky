extends GutTest

var world: DemoWorld

func before_each() -> void:
	world = DemoWorld.new()
	world.initialize(1234, {"all_dead": "continue"})
	world.state.nodes.clear()
	world.state.creatures.clear()
	world.state.structures.clear()
	world.state.drops.clear()
	world.add_player(1, "Host")
	world.add_player(2, "Guest")

func player(id: int = 1) -> Dictionary:
	return world.state.players[str(id)]

func give(id: String, count: int = 1, peer: int = 1) -> void:
	var inventory = world.inventory(player(peer))
	assert_eq(inventory.add_item(id, count), 0)
	player(peer).inventory = inventory.to_dict()

func count_item(id: String, peer: int = 1) -> int:
	return world.inventory(player(peer)).count_item(id)

func structure(kind: String) -> Dictionary:
	var result = world.entity(kind, [1.0, 0.0, 0.0])
	result.merge({"health": 200.0, "fuel": 0.0, "ingredients": [], "solvent": "", "remaining": 0.0, "output": "", "pending": "", "slots": [], "crop": "", "growth": 0.0})
	for i in 15:
		result.slots.append({})
	world.state.structures.append(result)
	return result

func test_pickup_is_once_only_and_checks_proximity() -> void:
	world.drop_item("twig", 3, [0.0, 0.0, 0.0])
	var uid = world.state.drops[0].uid
	player(2).position = [20.0, 0.0, 0.0]
	assert_false(world.action(2, "pickup", {"uid": uid}))
	assert_eq(world.state.drops.size(), 1)
	assert_true(world.action(1, "pickup", {"uid": uid}))
	player(2).position = [0.0, 0.0, 0.0]
	assert_false(world.action(2, "pickup", {"uid": uid}))
	assert_eq(count_item("twig"), 3)
	assert_eq(count_item("twig", 2), 0)
	assert_eq(world.state.drops.size(), 0)

func test_untrusted_requests_cannot_modify_inventory() -> void:
	give("twig", 5)
	var before = player().inventory.duplicate(true)
	for args in [{"slot": -1}, {"slot": 15}, {"slot": "0"}, {"slot": 0, "count": -1}, {"slot": 0, "count": 9999}]:
		assert_false(world.action(1, "drop", args))
	assert_false(world.action(999, "drop", {"slot": 0}))
	assert_false(world.action(1, "craft", {"recipe": {"result": "spear"}}))
	assert_eq(player().inventory, before)
	assert_eq(world.state.drops.size(), 0)

func test_ghost_cannot_pickup_craft_or_fight() -> void:
	give("twig", 2)
	world.life.die(world, player())
	assert_true(player().ghost)
	assert_eq(count_item("twig"), 0)
	assert_eq(world.state.drops.size(), 1)
	var uid = world.state.drops[0].uid
	for verb in ["pickup", "work", "attack", "craft", "ability"]:
		assert_false(world.action(1, verb, {"uid": uid, "recipe": "flint_axe", "name": "beast"}))
	assert_eq(world.state.drops.size(), 1)

func test_failed_craft_is_atomic_then_success_consumes_exactly() -> void:
	give("twig", 2)
	give("flint", 1)
	var before = player().inventory.duplicate(true)
	assert_false(world.action(1, "craft", {"recipe": "flint_axe"}))
	assert_eq(player().inventory, before)
	give("flint", 1)
	assert_true(world.action(1, "craft", {"recipe": "flint_axe"}))
	assert_eq(count_item("twig"), 0)
	assert_eq(count_item("flint"), 0)
	assert_eq(count_item("flint_axe"), 1)
	assert_has(world.state.discovered, "flint_axe")

func test_eating_consumes_food_and_restores_stamina() -> void:
	give("spirit_fruit")
	player().stats.stamina = 50.0
	assert_true(world.action(1, "use", {"slot": 0}))
	assert_gt(float(player().stats.stamina), 50.0)
	assert_eq(count_item("spirit_fruit"), 0)

func test_material_cannot_be_eaten_or_equipped() -> void:
	give("twig", 3)
	var before = player().inventory.duplicate(true)
	assert_false(world.action(1, "use", {"slot": 0}))
	assert_false(world.action(1, "equip", {"slot": 0}))
	assert_eq(player().inventory, before)

func test_shared_pot_enforces_four_and_single_output() -> void:
	var pot = structure("cooking_pot")
	give("spirit_fruit", 2, 1)
	give("spirit_fruit", 3, 2)
	for peer in [1, 2, 1]:
		assert_true(world.action(peer, "insert", {"uid": pot.uid, "slot": 0}))
	assert_false(world.action(1, "cook", {"uid": pot.uid}))
	assert_true(world.action(2, "insert", {"uid": pot.uid, "slot": 0}))
	assert_false(world.action(2, "insert", {"uid": pot.uid, "slot": 0}))
	assert_true(world.action(1, "cook", {"uid": pot.uid}))
	assert_false(world.action(2, "cook", {"uid": pot.uid}))
	assert_eq(pot.ingredients.size(), 0)
	world.Structures.step(world, 30.0)
	assert_true(world.action(2, "take", {"uid": pot.uid}))
	assert_false(world.action(1, "take", {"uid": pot.uid}))
	assert_eq(count_item("fruit_salad", 2), 1)

func test_spring_farming_and_ability_costs() -> void:
	var farm = structure("farm")
	give("seed")
	assert_true(world.action(1, "plant", {"uid": farm.uid, "slot": 0}))
	give("spirit_water")
	assert_true(world.action(1, "water", {"uid": farm.uid, "mode": "water"}))
	assert_true(farm.watered)
	assert_gt(float(farm.growth), 0.0)
	assert_eq(count_item("spirit_water"), 0)
	var growth = farm.growth
	world.Spring.step(world, 10.0)
	assert_gt(float(farm.growth), float(growth) + 10.0)
	var stamina = player().stats.stamina
	assert_true(world.action(1, "ability", {"name": "beast"}))
	assert_eq(player().stats.stamina, stamina - 30.0)
	assert_false(world.action(1, "ability", {"name": "beast"}))
	assert_true(world.action(1, "ability", {"name": "sense"}))
	assert_false(world.action(1, "ability", {"name": "sense"}))

func test_restore_and_same_name_reconnect_keep_progress() -> void:
	give("spear")
	player().stats.health = 71.0
	player().position = [3.0, 0.0, 4.0]
	world.remove_player(1)
	var saved = world.snapshot()
	var restored = DemoWorld.new()
	restored.restore(saved)
	restored.add_player(8, "Host")
	var returning = restored.state.players["8"]
	assert_eq(restored.inventory(returning).count_item("spear"), 1)
	assert_eq(returning.stats.health, 71.0)
	assert_eq(returning.position, [3.0, 0.0, 4.0])
	assert_false(restored.state.offline_players.has("Host"))
