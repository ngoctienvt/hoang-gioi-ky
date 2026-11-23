extends RefCounted
## Builds structures the way a player does (ingredients in the bag, then action("place")) so tests
## exercise the real placement path and the fields it sets (melt, slots, flags).


## Grants the recipe's ingredients to the player, places the structure at pos and returns it
## (empty when the host refused the placement).
static func place(world, peer_id: int, recipe_id: String, pos: Array) -> Dictionary:
	var player: Dictionary = world.state.players[str(peer_id)]
	var recipe: Dictionary = world.recipe(recipe_id)
	var inv = world.inventory(player)
	for id in recipe.get("ingredients", {}):
		inv.add_item(str(id), int(recipe.ingredients[id]))
	player.inventory = inv.to_dict()
	if not world.action(peer_id, "place", {"recipe": recipe_id, "position": pos}):
		return {}
	for s in world.index.entities_near(pos, 0.1, "structures"):
		if str(s.kind) == world.structure_kind(recipe):
			return s
	return {}


## Puts count of item into the structure through the player's bag and the chest_put action.
static func store(world, peer_id: int, structure: Dictionary, item_id: String, count: int) -> void:
	var player: Dictionary = world.state.players[str(peer_id)]
	for _i in count:
		var inv = world.inventory(player)
		inv.add_item(item_id, 1)
		player.inventory = inv.to_dict()
		var slot := -1
		for i in player.inventory.slots.size():
			if not player.inventory.slots[i].is_empty() and str(player.inventory.slots[i].id) == item_id:
				slot = i
				break
		world.action(peer_id, "chest_put", {"uid": structure.uid, "slot": slot})


static func stored_count(structure: Dictionary, item_id: String) -> int:
	var total := 0
	for slot in structure.get("slots", []):
		if slot is Dictionary and str(slot.get("id", "")) == item_id:
			total += int(slot.get("count", 0))
	return total


static func dropped_count(world, item_id: String) -> int:
	var total := 0
	for drop in world.state.drops:
		if str(drop.get("id", "")) == item_id:
			total += int(drop.get("count", 0))
	return total
