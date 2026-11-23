extends GutTest


func _make_world() -> GameWorld:
	var w := GameWorld.new()
	w.initialize(901, {"day_length": 480})
	w.clear_entities()
	w.add_player(1, "Slayer")
	w.action(1, "choose_character", {"character": "beast_bloodline"})
	return w


func _add_altar(w: GameWorld, biome: String, pos: Array = [2.0, 0.0, 0.0]) -> Dictionary:
	var altar: Dictionary = w.entity("altar", pos)
	altar.merge({"biome": biome})
	w.add_entity("nodes", altar)
	return altar


func test_summon_boss_at_altar_and_ghost_general_counterplay() -> void:
	var w := _make_world()
	var p: Dictionary = w.state.players["1"]
	var altar := _add_altar(w, "nether_swamp")
	var inv = w.inventory(p)
	inv.add_item("monster_core_low", 3)
	p.inventory = inv.to_dict()

	assert_true(w.action(1, "summon_boss", {"uid": altar.uid}))
	assert_eq(w.inventory(p).count_item("monster_core_low"), 0)
	assert_eq(w.state.creatures.size(), 1)
	var boss: Dictionary = w.state.creatures[0]
	assert_eq(boss.kind, "boss_ghost_general")
	assert_true(boss.get("is_boss", false))
	# Cannot summon second boss in same biome while alive
	inv = w.inventory(p)
	inv.add_item("monster_core_low", 3)
	p.inventory = inv.to_dict()
	assert_false(w.action(1, "summon_boss", {"uid": altar.uid}))

	# Shrouded Ghost General takes 0 damage without lantern / u_minh / pierce_mist
	var hp_before := float(boss.health)
	p.position = [boss.position[0] - 1.5, 0.0, boss.position[2]]
	assert_true(w.action(1, "attack", {"uid": boss.uid}))
	assert_eq(float(boss.health), hp_before)

	# Placing soul_lantern near boss reveals it and allows full damage
	var lantern: Dictionary = w.entity("soul_lantern", boss.position.duplicate())
	lantern.merge({"health": 200.0, "fuel": 0.0, "ingredients": [], "solvent": "", "remaining": 0.0, "output": "", "pending": "", "slots": []})
	w.add_entity("structures", lantern)
	p.attack_cd = 0.0
	assert_true(w.action(1, "attack", {"uid": boss.uid}))
	assert_lt(float(boss.health), hp_before)


func test_all_six_biome_bosses_counterplay_and_drops() -> void:
	var w := _make_world()
	var p: Dictionary = w.state.players["1"]

	# 1. Flame Wolf + Frost Talisman stun
	var wolf_altar := _add_altar(w, "crimson_volcano", [2.0, 0.0, 0.0])
	var inv = w.inventory(p)
	inv.add_item("monster_core_mid", 3)
	inv.add_item("frost_talisman", 1)
	p.inventory = inv.to_dict()
	assert_true(w.action(1, "summon_boss", {"uid": wolf_altar.uid}))
	var wolf: Dictionary = w.state.creatures.back()
	assert_eq(wolf.kind, "boss_flame_wolf")
	assert_true(w.action(1, "throw_talisman", {"slot": 1, "uid": wolf.uid}))
	assert_gt(float(wolf.effects.get("slow", {}).get("time", 0.0)), 0.0)

	# 2. Iron Turtle shell crack near lightning_rod
	var turtle_altar := _add_altar(w, "bamboo_forest", [2.0, 0.0, 0.0])
	inv = w.inventory(p)
	inv.add_item("monster_core_mid", 3)
	p.inventory = inv.to_dict()
	assert_true(w.action(1, "summon_boss", {"uid": turtle_altar.uid}))
	var turtle: Dictionary = w.state.creatures.back()
	assert_eq(turtle.kind, "boss_iron_turtle")
	var dmg_armored := float(w.Bosses.modify_incoming_damage(w, turtle, p, 100.0, {}))
	var rod: Dictionary = w.entity("lightning_rod", turtle.position.duplicate())
	rod.merge({"health": 200.0, "fuel": 0.0, "ingredients": [], "solvent": "", "remaining": 0.0, "output": "", "pending": "", "slots": []})
	w.add_entity("structures", rod)
	w.step(0.2)
	var dmg_cracked := float(w.Bosses.modify_incoming_damage(w, turtle, p, 100.0, {}))
	assert_gt(dmg_cracked, dmg_armored * 3.0)

	# 3. Ancient Warden shield break via bind_talisman
	var warden_altar := _add_altar(w, "ancient_ruins", [2.0, 0.0, 0.0])
	inv = w.inventory(p)
	inv.add_item("monster_core_high", 3)
	inv.add_item("bind_talisman", 1)
	p.inventory = inv.to_dict()
	assert_true(w.action(1, "summon_boss", {"uid": warden_altar.uid}))
	var warden: Dictionary = w.state.creatures.back()
	assert_eq(warden.kind, "boss_ancient_warden")
	var dmg_shielded := float(w.Bosses.modify_incoming_damage(w, warden, p, 100.0, {}))
	assert_true(w.action(1, "throw_talisman", {"slot": 1, "uid": warden.uid}))
	var dmg_broken := float(w.Bosses.modify_incoming_damage(w, warden, p, 100.0, {}))
	assert_gt(dmg_broken, dmg_shielded * 4.0)

	# 4. Kill Frost Wyrm drops frost_wyrm_scale
	var wyrm_altar := _add_altar(w, "frost_peaks", [2.0, 0.0, 0.0])
	inv = w.inventory(p)
	inv.add_item("monster_core_high", 3)
	p.inventory = inv.to_dict()
	assert_true(w.action(1, "summon_boss", {"uid": wyrm_altar.uid}))
	var wyrm: Dictionary = w.state.creatures.back()
	assert_eq(wyrm.kind, "boss_frost_wyrm")
	w.Combat.kill(w, wyrm)
	var has_scale := false
	for d in w.state.drops:
		if str(d.get("id", "")) == "frost_wyrm_scale":
			has_scale = true
	assert_true(has_scale)
