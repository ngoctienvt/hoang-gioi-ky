extends RefCounted

static func extra(slot: Dictionary) -> Dictionary:
	var result = slot.duplicate(true)
	for key in ["id", "count", "uid", "kind", "position"]:
		result.erase(key)
	if result.get("durability", 0) == 0:
		result.erase("durability")
	return result

static func item(id: String) -> Dictionary:
	var value = ItemDB.get_item(id)
	if value == null:
		return {}
	return {"id": str(value.id), "damage": value.damage, "durability": value.max_durability, "tags": value.tags, "category": value.category, "tool_type": value.tool_type, "equipment_slot": "body" if id == "grass_armor" else "hand", "food": {"health": value.restore_health, "stamina": value.restore_stamina, "dao": value.restore_dao_heart}}

static func recipe(id: String) -> Dictionary:
	var value = RecipeDB.recipes.get(id)
	if value == null:
		return {}
	return {"id": str(value.id), "result": str(value.result.id), "count": value.result_count, "tier": value.tier, "ingredients": value.ingredients, "is_structure": value.is_structure, "resource": value}

static func valid_position(value) -> bool:
	if not value is Array or value.size() != 3:
		return false
	for number in value:
		if not (number is float or number is int) or not is_finite(float(number)) or absf(float(number)) > 40:
			return false
	return absf(float(value[1])) < 0.1

static func distance(a: Array, b: Array) -> float:
	return Vector2(float(a[0]), float(a[2])).distance_to(Vector2(float(b[0]), float(b[2])))

static func has_tool(world, player: Dictionary, tool: String) -> bool:
	var hand: Dictionary = player.inventory.equipment.get("hand", {})
	var types = {"axe": 1, "pickaxe": 2, "shovel": 3}
	if hand.is_empty():
		return false
	if tool == "hammer":
		return hand.id == "hammer"
	return int(world.item(hand.id).get("tool_type", 0)) == types.get(tool, -1)

static func wear_hand(player: Dictionary, amount: int) -> void:
	var hand: Dictionary = player.inventory.equipment.get("hand", {})
	if hand.is_empty() or int(hand.get("durability", 0)) <= 0:
		return
	hand.durability -= amount
	if hand.durability <= 0:
		player.inventory.equipment.hand = {}

static func hurt(world, player: Dictionary, amount: float) -> void:
	if player.ghost:
		return
	var armor: Dictionary = player.inventory.equipment.get("body", {})
	if not armor.is_empty():
		amount *= 0.6
		armor.durability = int(armor.get("durability", 0)) - 1
		if armor.durability <= 0:
			player.inventory.equipment.body = {}
	var stats = world.stats(player)
	stats.damage(amount)
	player.stats = stats.to_dict()
	player.hit_flash = 0.2
	if player.stats.health <= 0:
		world.life.die(world, player)
