extends GutTest


func test_add_remove_find_and_chunk_move() -> void:
	var world := GameWorld.new()
	world.initialize(101, {})
	world.clear_entities()

	var node := world.entity("rock", [5.0, 0.0, 5.0])
	world.add_entity("nodes", node)
	assert_eq(world.find_any(node.uid).uid, node.uid)
	assert_eq(world.index.entity_chunk.get(node.uid), "0,0")

	world.move_entity(node, [30.0, 0.0, 30.0], true)
	assert_eq(world.index.entity_chunk.get(node.uid), "1,1")
	assert_has(world.index.uids_in_chunk("1,1"), node.uid)
	assert_does_not_have(world.index.uids_in_chunk("0,0"), node.uid)

	world.remove_entity(node)
	assert_true(world.find_any(node.uid).is_empty())
	assert_false(world.index.entity_chunk.has(node.uid))


func test_index_rebuilt_after_restore() -> void:
	var world := GameWorld.new()
	world.initialize(202, {})
	var expected_count: int = world.index.by_uid.size()
	assert_gt(expected_count, 50)
	var sample_uid: int = int(world.state.nodes[0].uid)

	var saved := world.snapshot()
	var restored := GameWorld.new()
	restored.restore(saved)

	assert_eq(restored.index.by_uid.size(), expected_count)
	assert_false(restored.find_any(sample_uid).is_empty())
