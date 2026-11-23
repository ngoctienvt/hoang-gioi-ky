extends GutTest

const Season = preload("res://world/simulation/world_season.gd")


func test_season_progression_and_winter_phases() -> void:
	var world := GameWorld.new()
	world.initialize(42, {"day_length": 100.0})
	assert_eq(world.state.clock.season, "autumn")
	assert_eq(world.state.clock.season_day, 1)
	assert_eq(world.state.clock.days_to_next_season, 20)
	assert_false(world.state.clock.season_warning)

	# Day 18 of autumn -> 3 days remaining -> warning active
	world.state.clock.elapsed = 17.0 * 100.0 + 1.0
	Season.update_clock(world)
	assert_eq(world.state.clock.season, "autumn")
	assert_eq(world.state.clock.days_to_next_season, 3)
	assert_true(world.state.clock.season_warning)

	# After 20 days -> winter
	world.state.clock.elapsed = 20.0 * 100.0 + 1.0
	Season.update_clock(world)
	assert_eq(world.state.clock.season, "winter")
	assert_eq(world.state.clock.season_day, 1)
	assert_eq(world.state.clock.day_segments, 5)
	assert_eq(world.state.clock.dusk_segments, 5)
	assert_eq(world.state.clock.night_segments, 6)
	assert_eq(world.state.clock.phase, "day")

	# 6/16 into winter day -> dusk (since day=5/16, dusk=5/16..10/16)
	world.state.clock.elapsed = 20.0 * 100.0 + 100.0 * (6.0 / 16.0)
	Season.update_clock(world)
	assert_eq(world.state.clock.phase, "dusk")

	# 11/16 into winter day -> night
	world.state.clock.elapsed = 20.0 * 100.0 + 100.0 * (11.0 / 16.0)
	Season.update_clock(world)
	assert_eq(world.state.clock.phase, "night")


func test_seasons_disabled_fallback() -> void:
	var world := GameWorld.new()
	world.initialize(42, {"day_length": 100.0, "seasons": false})
	world.state.clock.elapsed = 25.0 * 100.0 + 60.0
	Season.update_clock(world)
	assert_eq(world.state.clock.season, "autumn")
	assert_eq(world.state.clock.phase, "dusk")
