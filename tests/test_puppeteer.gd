extends GutTest


func _make_world() -> GameWorld:
	var w := GameWorld.new()
	w.initialize(703, {"day_length": 480})
	w.clear_entities()
	w.add_player(1, "Puppeteer")
	w.action(1, "choose_character", {"character": "puppeteer"})
	return w


func test_puppeteer_stats_and_craft_discount() -> void:
	var w := _make_world()
	var p: Dictionary = w.state.players["1"]
	assert_eq(float(p.stats.max_health), 110.0)
	var desk := w.entity("talisman_desk", [1.0, 0.0, 0.0])
	desk.merge({"health": 200.0, "fuel": 0.0, "ingredients": [], "solvent": "", "remaining": 0.0, "output": "", "pending": "", "slots": []})
	w.add_entity("structures", desk)
	# bind_talisman normally takes talisman_paper:1, cinnabar:1, grass:2 -> discounted to grass:1
	var inv = w.inventory(p)
	inv.add_item("talisman_paper", 1)
	inv.add_item("cinnabar", 1)
	inv.add_item("grass", 1)
	p.inventory = inv.to_dict()
	assert_true(w.action(1, "craft", {"recipe": "bind_talisman"}))
	assert_eq(w.inventory(p).count_item("bind_talisman"), 2)
	var forge := w.entity("refining_forge", [2.0, 0.0, 0.0])
	forge.merge({"health": 200.0, "fuel": 0.0, "ingredients": [], "solvent": "", "remaining": 0.0, "output": "", "pending": "", "slots": []})
	w.add_entity("structures", forge)
	# puppet_haul normally wood:4, stone:2, spirit_stone:2 -> discounted to 3, 1, 1
	inv = w.inventory(p)
	inv.add_item("wood", 3)
	inv.add_item("stone", 1)
	inv.add_item("spirit_stone", 1)
	p.inventory = inv.to_dict()
	assert_true(w.action(1, "place", {"recipe": "puppet_haul", "position": [3.0, 0.0, 0.0]}))
	assert_eq(w.state.puppets.size(), 1)


func test_summon_and_command_guard_puppets_max_two() -> void:
	var w := _make_world()
	var p: Dictionary = w.state.players["1"]
	var inv = w.inventory(p)
	inv.add_item("spirit_stone", 6)
	p.inventory = inv.to_dict()
	assert_true(w.action(1, "ability", {"name": "summon_puppet"}))
	assert_eq(w.inventory(p).count_item("spirit_stone"), 4)
	p.ability_cds["summon_puppet"] = 0.0
	assert_true(w.action(1, "ability", {"name": "summon_puppet"}))
	assert_eq(w.inventory(p).count_item("spirit_stone"), 2)
	# Max 2 guard puppets
	p.ability_cds["summon_puppet"] = 0.0
	assert_false(w.action(1, "ability", {"name": "summon_puppet"}))
	assert_eq(w.inventory(p).count_item("spirit_stone"), 2)

	var wolf := w.entity("wolf", [10.0, 0.0, 0.0])
	wolf.merge({"health": 100.0, "max_health": 100.0, "state": "idle", "home": [10.0, 0.0, 0.0], "cooldown": 0.0, "respawn": 0.0, "hit_flash": 0.0, "stolen": [], "effects": {}})
	w.add_entity("creatures", wolf)
	assert_true(w.action(1, "ability", {"name": "command_puppet", "uid": wolf.uid}))
	for _i in 30:
		w.Puppets.step(w, 0.25)
	assert_lt(float(wolf.health), 100.0)
