extends GutTest

const BoundaryDao = preload("res://world/simulation/traits/boundary_dao.gd")


func _make_world() -> GameWorld:
	var w := GameWorld.new()
	w.initialize(704, {"day_length": 480})
	w.clear_entities()
	w.add_player(1, "YinYang")
	w.action(1, "choose_character", {"character": "yin_yang"})
	return w


func test_boundary_dao_sight_and_heart_demon_rules() -> void:
	var w := _make_world()
	var p: Dictionary = w.state.players["1"]
	assert_eq(float(p.stats.dao), 50.0)
	assert_true(BoundaryDao.in_boundary(p))
	# At Dao 50, no heart demon spawns
	w.HeartDemon.step(w, 0.1)
	assert_eq(w.HeartDemon._owned_demons(w, 1).size(), 0)
	# Can attack wraiths at Dao 50
	var wraith := w.entity("wraith", [1.5, 0.0, 0.0])
	wraith.merge({"health": 60.0, "max_health": 60.0, "state": "idle", "home": [1.5, 0.0, 0.0], "cooldown": 0.0, "respawn": 0.0, "hit_flash": 0.0, "stolen": [], "effects": {}})
	w.add_entity("creatures", wraith)
	assert_true(w.action(1, "attack", {"uid": wraith.uid}))
	assert_lt(float(wraith.health), 60.0)

	# Slipping out of 35-65 spawns heart demon immediately
	p.stats.dao = 30.0
	w.HeartDemon.step(w, 0.1)
	assert_eq(w.HeartDemon._owned_demons(w, 1).size(), 1)
	p.stats.dao = 50.0
	w.HeartDemon.step(w, 0.1)
	assert_eq(w.HeartDemon._owned_demons(w, 1).size(), 0)
	p.stats.dao = 70.0
	w.HeartDemon.step(w, 0.1)
	assert_eq(w.HeartDemon._owned_demons(w, 1).size(), 1)


func test_shadow_step_requires_dark_and_adds_sin() -> void:
	var w := _make_world()
	var p: Dictionary = w.state.players["1"]
	w.state.clock["phase"] = "day"
	assert_false(w.action(1, "ability", {"name": "shadow_step", "direction": [1.0, 0.0]}))
	w.state.clock["phase"] = "night"
	assert_true(w.action(1, "ability", {"name": "shadow_step", "direction": [1.0, 0.0]}))
	assert_almost_eq(float(p.position[0]), 6.0, 0.01)
	assert_lt(float(p.stats.dao), 50.0)
	assert_gt(float(w.state.karma.sin), 0.0)
