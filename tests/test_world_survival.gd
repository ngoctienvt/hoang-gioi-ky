extends GutTest

var world: GameWorld
var player: Dictionary

func before_each() -> void:
	world = GameWorld.new()
	world.initialize(42, {})
	world.clear_entities()
	world.add_player(1, "Host")
	world.add_player(2, "Guest")
	player = world.state.players["1"]

func give(id: String, count: int = 1) -> void:
	var inv = world.inventory(player)
	assert_eq(inv.add_item(id, count), 0)
	player.inventory = inv.to_dict()

func structure(kind: String) -> Dictionary:
	var target = world.entity(kind, [1.0, 0.0, 0.0])
	target.merge({"health": 200.0, "fuel": 90.0, "ingredients": [], "solvent": "", "remaining": 0.0, "output": "", "pending": "", "slots": [], "crop": "", "growth": 0.0})
	for i in 15:
		target.slots.append({})
	world.add_entity("structures", target)
	return target

func test_altar_consumes_stones_and_penalty_persists_tick() -> void:
	var altar = structure("resurrection_altar")
	var storage = InventoryComponent.new()
	storage.add_item("spirit_stone", 2)
	altar.slots = storage.slots
	world.life.die(world, player)
	assert_true(world.action(1, "revive", {"uid": altar.uid}))
	assert_false(player.ghost)
	assert_eq(world.inventory({"inventory": {"slots": altar.slots}}).count_item("spirit_stone"), 0)
	assert_eq(float(player.stats.max_health), 112.5)
	world.step(0.1)
	assert_eq(float(player.stats.max_health), 112.5)

func test_rock_exhaustion_prevents_repeated_loot() -> void:
	give("flint_pickaxe")
	assert_true(world.action(1, "equip", {"slot": 0}))
	var rock = world.entity("rock", [1.0, 0.0, 0.0])
	rock.merge({"stage": 0, "hits": 0, "depleted": false, "regrow": 0.0})
	world.add_entity("nodes", rock)
	for i in 9:
		player.work_cd = 0.0
		assert_true(world.action(1, "work", {"uid": rock.uid}))
	assert_true(rock.depleted)
	var drops = world.state.drops.duplicate(true)
	player.work_cd = 0.0
	assert_false(world.action(1, "work", {"uid": rock.uid}))
	assert_eq(world.state.drops, drops)

func test_roast_requires_burning_fire_and_food_can_be_consumed() -> void:
	var fire = structure("campfire")
	give("small_meat")
	fire.fuel = 0.0
	assert_false(world.action(1, "cook", {"uid": fire.uid, "slot": 0}))
	fire.fuel = 10.0
	assert_true(world.action(1, "cook", {"uid": fire.uid, "slot": 0}))
	var inv = world.inventory(player)
	assert_eq(inv.count_item("small_meat"), 0)
	assert_eq(inv.count_item("roasted_meat"), 1)
	player.stats.stamina = 50.0
	assert_true(world.action(1, "use", {"slot": 0}))
	assert_gt(float(player.stats.stamina), 50.0)

func test_team_damage_requires_uncontrolled_beast() -> void:
	var guest: Dictionary = world.state.players["2"]
	assert_false(world.action(1, "attack", {"peer_id": 2}))
	assert_eq(float(guest.stats.health), 150.0)
	assert_true(world.action(1, "ability", {"name": "beast"}))
	assert_false(world.action(1, "attack", {"peer_id": 2}))
	player.stats.stamina = 0.0
	player.beast_time = 0.0
	world.step(0.1)
	assert_true(player.mad)
	assert_lt(float(guest.stats.health), 150.0)
	assert_gt(float(player.attack_cd), 0.0)

func test_spirit_water_expires_and_remains_valid_item() -> void:
	give("spirit_water")
	player.inventory.slots[0].expires = 1.0
	world.state.clock.elapsed = 2.0
	world.Spring.step(world, 0.1)
	assert_eq(player.inventory.slots[0].id, "plain_water")
	assert_eq(world.inventory(player).count_item("plain_water"), 1)
