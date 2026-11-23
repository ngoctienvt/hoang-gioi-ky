extends GutTest


func _make_world() -> GameWorld:
	var w := GameWorld.new()
	w.initialize(404, {"day_length": 480})
	w.clear_entities()
	w.add_player(1, "Tester")
	return w


func _spawn_wolf(w: GameWorld, pos: Array = [1.5, 0.0, 0.0]) -> Dictionary:
	var wolf: Dictionary = w.entity("wolf", pos)
	wolf.merge({"health": 200.0, "state": "chase", "home": pos.duplicate(), "cooldown": 0.0, "respawn": 0.0, "hit_flash": 0.0, "stolen": [], "effects": {}})
	w.add_entity("creatures", wolf)
	return wolf


func test_all_six_temper_waters_and_expiry() -> void:
	var w := _make_world()
	var p: Dictionary = w.state.players["1"]
	var inv = w.inventory(p)
	inv.add_item("spear", 1)
	inv.add_item("spirit_water_thanh_moc", 1)
	inv.add_item("spirit_water_xich_viem", 1)
	inv.add_item("spirit_water_huyen_bang", 1)
	inv.add_item("spirit_water_co_van", 1)
	inv.add_item("spirit_water_u_minh", 1)
	p.inventory = inv.to_dict()
	assert_true(w.action(1, "temper", {"slot": 0, "water_slot": 1}))
	assert_true(w.action(1, "equip", {"slot": 0}))
	p.stats.health = 100.0
	var wolf := _spawn_wolf(w)
	assert_true(w.action(1, "attack", {"uid": wolf.uid}))
	assert_eq(float(p.stats.health), 102.0)

	# Re-temper replaces previous temper
	assert_true(w.action(1, "unequip", {"slot": "hand"}))
	inv = w.inventory(p)
	var spear_idx := -1
	var xich_idx := -1
	for i in inv.slots.size():
		if inv.slots[i].get("id", "") == "spear":
			spear_idx = i
		elif inv.slots[i].get("id", "") == "spirit_water_xich_viem":
			xich_idx = i
	assert_true(w.action(1, "temper", {"slot": spear_idx, "water_slot": xich_idx}))
	assert_eq(inv.slots[spear_idx] if spear_idx < 0 else p.inventory.slots[spear_idx].temper.type, "xich_viem")
	assert_true(w.action(1, "equip", {"slot": spear_idx}))
	p.attack_cd = 0.0
	assert_true(w.action(1, "attack", {"uid": wolf.uid}))
	assert_true(w.Effects.has(wolf, "burn"))

	# Co Van clears temper
	assert_true(w.action(1, "unequip", {"slot": "hand"}))
	inv = w.inventory(p)
	var co_idx := -1
	for i in inv.slots.size():
		if inv.slots[i].get("id", "") == "spear":
			spear_idx = i
		elif inv.slots[i].get("id", "") == "spirit_water_co_van":
			co_idx = i
	assert_true(w.action(1, "temper", {"slot": spear_idx, "water_slot": co_idx}))
	assert_false(p.inventory.slots[spear_idx].has("temper"))

	# U Minh hits wraith
	var wraith: Dictionary = w.entity("wraith", [1.5, 0.0, 0.0])
	wraith.merge({"health": 70.0, "state": "chase", "home": [1.5, 0.0, 0.0], "cooldown": 0.0, "respawn": 0.0, "hit_flash": 0.0, "stolen": [], "effects": {}, "no_respawn": true})
	w.add_entity("creatures", wraith)
	assert_true(w.action(1, "equip", {"slot": spear_idx}))
	p.attack_cd = 0.0
	assert_false(w.action(1, "attack", {"uid": wraith.uid}))
	assert_true(w.action(1, "unequip", {"slot": "hand"}))
	inv = w.inventory(p)
	var uminh_idx := -1
	for i in inv.slots.size():
		if inv.slots[i].get("id", "") == "spear":
			spear_idx = i
		elif inv.slots[i].get("id", "") == "spirit_water_u_minh":
			uminh_idx = i
	assert_true(w.action(1, "temper", {"slot": spear_idx, "water_slot": uminh_idx}))
	assert_true(w.action(1, "equip", {"slot": spear_idx}))
	p.attack_cd = 0.0
	assert_true(w.action(1, "attack", {"uid": wraith.uid}))
	assert_eq(int(p.inventory.equipment.hand.temper.hits), 19)
	p.inventory.equipment.hand.temper.hits = 1
	p.attack_cd = 0.0
	assert_true(w.action(1, "attack", {"uid": wraith.uid}))
	assert_false(p.inventory.equipment.hand.has("temper"))


func test_save_migration_v5_to_v7_converts_vitality_hits() -> void:
	var v5 := {
		"version": 5,
		"state": {
			"seed": 99,
			"players": {"1": {"name": "A", "inventory": {"slots": [{"id": "spear", "count": 1, "vitality_hits": 12}], "equipment": {"hand": {}, "body": {}, "head": {}}}}},
			"creatures": [],
		}
	}
	var migrated := SaveManager.migrate_envelope(v5)
	assert_false(migrated.is_empty())
	var slot: Dictionary = migrated.players["1"].inventory.slots[0]
	assert_false(slot.has("vitality_hits"))
	assert_eq(slot.temper.type, "thanh_moc")
	assert_eq(int(slot.temper.hits), 12)
	assert_true(migrated.has("karma"))
	assert_true(migrated.has("npcs"))
