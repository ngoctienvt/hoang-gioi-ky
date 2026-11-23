extends GutTest


func _make_world() -> GameWorld:
	var w := GameWorld.new()
	w.initialize(909, {"day_length": 480, "karma": true})
	w.clear_entities()
	w.add_player(1, "Tester")
	return w


func _empty_slots() -> Array:
	var slots: Array = []
	slots.resize(15)
	for i in 15:
		slots[i] = {}
	return slots


func test_merchant_trade_and_leave_after_one_day() -> void:
	var w := _make_world()
	var ev := KarmaEventDef.new()
	ev.kind = "spawn_npc"
	ev.params = {"faction": "merchant", "offers": [{"id": "conceal_pill", "count": 1, "currency": "spirit_stone", "price": 2}]}
	w.Karma.Events.execute(w, ev)
	assert_eq(w.state.npcs.size(), 1)
	var npc: Dictionary = w.state.npcs[0]
	var p: Dictionary = w.state.players["1"]
	p.position = npc.position.duplicate()
	var inv = w.inventory(p)
	inv.add_item("spirit_stone", 2)
	p.inventory = inv.to_dict()
	assert_true(w.action(1, "trade", {"uid": npc.uid, "offer": 0}))
	assert_eq(w.inventory(p).count_item("conceal_pill"), 1)
	w.Npcs.step(w, w.day_length() + 1.0)
	assert_eq(w.state.npcs.size(), 0)


func test_beggar_steals_normal_chest_not_talisman_chest() -> void:
	var w := _make_world()
	var tc: Dictionary = w.entity("talisman_chest", [2.0, 0.0, 0.0])
	var tc_slots := _empty_slots()
	tc_slots[0] = {"id": "bind_talisman", "count": 2}
	tc.merge({"health": 200.0, "fuel": 0.0, "ingredients": [], "solvent": "", "remaining": 0.0, "output": "", "pending": "", "slots": tc_slots, "crop": "", "growth": 0.0})
	w.add_entity("structures", tc)
	var ev := KarmaEventDef.new()
	ev.kind = "steal_chest"
	w.Karma.Events.execute(w, ev)
	assert_eq(int(tc.slots[0].count), 2)
	assert_eq(w.state.npcs.size(), 0)

	var chest: Dictionary = w.entity("chest", [4.0, 0.0, 0.0])
	var c_slots := _empty_slots()
	c_slots[0] = {"id": "wood", "count": 5}
	chest.merge({"health": 200.0, "fuel": 0.0, "ingredients": [], "solvent": "", "remaining": 0.0, "output": "", "pending": "", "slots": c_slots, "crop": "", "growth": 0.0})
	w.add_entity("structures", chest)
	w.Karma.Events.execute(w, ev)
	assert_lt(int(chest.slots[0].count), 5)
	assert_eq(w.state.npcs.size(), 1)


func test_wanderer_guest_altar_recipe_tame_and_portal() -> void:
	var w := _make_world()
	var p: Dictionary = w.state.players["1"]
	var ev_w := KarmaEventDef.new()
	ev_w.kind = "spawn_npc"
	ev_w.params = {"faction": "wanderer", "requests": [{"id": "wood", "count": 2}]}
	w.Karma.Events.execute(w, ev_w)
	var npc: Dictionary = w.state.npcs[0]
	p.position = npc.position.duplicate()
	var inv = w.inventory(p)
	inv.add_item("wood", 2)
	p.inventory = inv.to_dict()
	assert_true(w.action(1, "fulfill_request", {"uid": npc.uid}))
	assert_eq(w.inventory(p).count_item("spirit_stone"), 3)
	assert_gt(float(w.state.karma.fate), 0.0)

	# Guest altar invites without changing karma
	var altar: Dictionary = w.entity("guest_altar", [0.0, 0.0, 0.0])
	altar.merge({"health": 200.0, "fuel": 0.0, "ingredients": [], "solvent": "", "remaining": 0.0, "output": "", "pending": "", "slots": _empty_slots(), "crop": "", "growth": 0.0})
	w.add_entity("structures", altar)
	p.position = [0.5, 0.0, 0.0]
	inv = w.inventory(p)
	inv.add_item("incense", 1)
	p.inventory = inv.to_dict()
	var fate_before := float(w.state.karma.fate)
	assert_true(w.action(1, "invite_guest", {"uid": altar.uid, "guest_type": "merchant"}))
	assert_eq(float(w.state.karma.fate), fate_before)
	assert_eq(w.state.npcs.size(), 1)

	# grant_recipe, tame_beast, open_secret_realm
	var ev_r := KarmaEventDef.new()
	ev_r.kind = "grant_recipe"
	ev_r.params = {"recipe_id": "forbidden_conceal_pill"}
	w.Karma.Events.execute(w, ev_r)
	assert_true("forbidden_conceal_pill" in w.state.forbidden_recipes)

	var ev_t := KarmaEventDef.new()
	ev_t.kind = "tame_beast"
	w.Karma.Events.execute(w, ev_t)
	assert_eq(w.state.creatures.size(), 1)
	assert_true(w.state.creatures[0].get("ally", false))

	var ev_p := KarmaEventDef.new()
	ev_p.kind = "open_secret_realm"
	w.Karma.Events.execute(w, ev_p)
	assert_eq(w.state.nodes.size(), 1)
	assert_eq(w.state.nodes[0].kind, "secret_realm_portal")
