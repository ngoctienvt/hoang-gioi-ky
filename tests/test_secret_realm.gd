extends GutTest


func _make_world() -> GameWorld:
	var w := GameWorld.new()
	w.initialize(902, {"day_length": 480})
	w.clear_entities()
	w.add_player(1, "Explorer")
	return w


func test_secret_realm_full_loop_enter_puzzle_claim_exit() -> void:
	var w := _make_world()
	var p: Dictionary = w.state.players["1"]
	p.position = [6.0, 0.0, 6.0]

	# Trigger full moon night to spawn portal naturally
	w.state.clock["elapsed"] = 6.0 * 480.0 + 440.0
	w.step(0.5)
	var portal: Dictionary = {}
	for n in w.state.nodes:
		if str(n.get("kind", "")) == "secret_realm_portal":
			portal = n
			break
	assert_false(portal.is_empty())

	# Enter Secret Realm
	p.position = portal.position.duplicate()
	assert_true(w.action(1, "enter_secret_realm", {"uid": portal.uid}))
	assert_true(p.get("in_secret_realm", false))
	assert_gt(float(p.position[0]), 1000.0)

	# Activate all 3 rune switches -> unlocks chest
	var switches: Array = []
	var chest: Dictionary = {}
	var exit_node: Dictionary = {}
	for n in w.state.nodes:
		var k := str(n.get("kind", ""))
		if k == "realm_switch":
			switches.append(n)
		elif k == "realm_chest":
			chest = n
		elif k == "secret_realm_exit":
			exit_node = n
	assert_eq(switches.size(), 3)
	assert_false(chest.is_empty())
	assert_false(exit_node.is_empty())

	# Cannot claim before all 3 switches active
	p.position = chest.position.duplicate()
	assert_false(w.action(1, "claim_vault", {"uid": chest.uid}))

	for sw in switches:
		p.position = sw.position.duplicate()
		assert_true(w.action(1, "activate_switch", {"uid": sw.uid}))
	assert_true(chest.get("unlocked", false))

	p.position = chest.position.duplicate()
	assert_true(w.action(1, "claim_vault", {"uid": chest.uid}))
	assert_gt(w.inventory(p).count_item("spirit_stone"), 0)

	# Exit returns to original position
	p.position = exit_node.position.duplicate()
	assert_true(w.action(1, "exit_secret_realm", {"uid": exit_node.uid}))
	assert_false(p.get("in_secret_realm", false))
	assert_lt(float(p.position[0]), 50.0)


func test_secret_realm_portal_expiry_ejects_player() -> void:
	var w := _make_world()
	var p: Dictionary = w.state.players["1"]
	var portal: Dictionary = w.entity("secret_realm_portal", [1.0, 0.0, 1.0])
	portal.merge({"lifetime": 1.0})
	w.add_entity("nodes", portal)

	p.position = [1.0, 0.0, 1.0]
	assert_true(w.action(1, "enter_secret_realm", {"uid": portal.uid}))
	assert_true(p.get("in_secret_realm", false))

	# Advance past portal lifetime -> safely ejected
	w.state.options["secret_realm"] = false
	w.step(0.6)
	w.step(0.6)
	assert_false(p.get("in_secret_realm", false))
	assert_lt(float(p.position[0]), 50.0)
