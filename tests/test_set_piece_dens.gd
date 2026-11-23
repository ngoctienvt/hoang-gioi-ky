extends GutTest
## Den set pieces carry which creatures live there; the generator spawns them from that data.

const Rules = preload("res://world/simulation/world_rules.gd")
const PIECE_DIR := "res://data/set_pieces/"


func _pieces() -> Array:
	var out: Array = []
	for file in DirAccess.get_files_at(PIECE_DIR):
		if file.ends_with(".tres"):
			out.append(load(PIECE_DIR + file))
	return out


func test_set_piece_den_spawns_name_real_creatures() -> void:
	for piece in _pieces():
		for entry in piece.entries:
			var spawn := str(entry.get("spawn", ""))
			if spawn.is_empty():
				continue
			assert_not_null(Rules.creature(spawn), "%s/%s spawns unknown '%s'" % [piece.id, entry.kind, spawn])
			assert_gt(int(entry.get("count", 0)), 0, "%s/%s spawns nobody" % [piece.id, entry.kind])


func test_set_piece_frost_den_keeps_ice_wolves_beyond_notice_of_their_prey() -> void:
	# Arrange
	var piece: SetPieceDef = load(PIECE_DIR + "frost_den.tres")
	var wolf_at := Vector2.ZERO
	var herd_at := Vector2.ZERO
	for entry in piece.entries:
		if str(entry.get("spawn", "")) == "ice_wolf":
			wolf_at = entry.offset
		elif str(entry.get("spawn", "")) == "thick_fur_beast":
			herd_at = entry.offset

	# Act
	var gap := wolf_at.distance_to(herd_at) - 3.0  # creatures wander up to 1.5 m from each den

	# Assert
	assert_gt(gap, float(Rules.creature("ice_wolf").detect_range), "the pack would wipe out the herd at world start")


func test_set_piece_generated_world_has_starter_dens_and_swamp_wraiths() -> void:
	# Arrange / Act
	var world := GameWorld.new()
	world.initialize(4242, {"day_length": 480.0})

	# Assert
	var kinds := {}
	for c in world.state.creatures:
		kinds[str(c.kind)] = int(kinds.get(str(c.kind), 0)) + 1
	for starter in ["rabbit", "wolf", "monkey"]:
		assert_gt(int(kinds.get(starter, 0)), 0, "starter %s spawned from forest_starter data" % starter)
	assert_gt(int(kinds.get("wraith", 0)), 0, "the swamp den now houses wraiths")
