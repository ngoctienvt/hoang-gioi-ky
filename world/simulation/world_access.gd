extends RefCounted

static func extra(slot: Dictionary) -> Dictionary:
	var result := slot.duplicate(true)
	for key in ["id", "count", "uid", "kind", "position"]:
		result.erase(key)
	if result.get("durability", 0) == 0:
		result.erase("durability")
	return result


static func return_bottle(world, inv, position: Array) -> void:
	if inv.add_item("water_bottle", 1) > 0:
		world.drop_item("water_bottle", 1, position)


static func item(id: String) -> Dictionary:
	var value := ItemDB.get_item(id)
	if value == null:
		return {}
	var slot_name := String(value.equipment_slot)
	if slot_name.is_empty():
		slot_name = "body" if id == "grass_armor" else "hand"
	return {
		"id": str(value.id),
		"damage": value.damage,
		"durability": value.max_durability,
		"tags": value.tags,
		"effects": value.get("effects") if value.get("effects") != null else {},
		"talisman_effect": str(value.get("talisman_effect") if value.get("talisman_effect") != null else ""),
		"category": value.category,
		"tool_type": value.tool_type,
		"tool_tier": value.get("tool_tier") if value.get("tool_tier") != null else 1,
		"equipment_slot": slot_name,
		"insulation": value.insulation,
		"cooling": value.cooling,
		"waterproof": value.waterproof,
		"spoil_time": value.spoil_time,
		"warm_effect": value.warm_effect,
		"cool_effect": value.cool_effect,
		"food": {"health": value.restore_health, "stamina": value.restore_stamina, "dao": value.restore_dao_heart},
	}


static func recipe(id: String) -> Dictionary:
	var value = RecipeDB.recipes.get(id)
	if value == null:
		return {}
	return {
		"id": str(value.id),
		"result": str(value.result.id),
		"count": value.result_count,
		"tier": value.tier,
		"station": str(value.get("station") if value.get("station") != null else ""),
		"forbidden_unlock": bool(value.get("forbidden_unlock") if value.get("forbidden_unlock") != null else false),
		"ingredients": value.ingredients,
		"is_structure": value.is_structure,
		"resource": value,
	}


static func valid_position(value, limit: float = 40.0) -> bool:
	if not value is Array or value.size() != 3:
		return false
	for number in value:
		if not (number is float or number is int) or not is_finite(float(number)) or absf(float(number)) > limit:
			return false
	return absf(float(value[1])) < 0.1


static func distance(a: Array, b: Array) -> float:
	return Vector2(float(a[0]), float(a[2])).distance_to(Vector2(float(b[0]), float(b[2])))


static func has_tool(world, player: Dictionary, tool: String, min_tier: int = 1) -> bool:
	var hand: Dictionary = player.inventory.equipment.get("hand", {})
	var types := {"axe": 1, "pickaxe": 2, "shovel": 3}
	if hand.is_empty():
		return false
	if tool == "hammer":
		return hand.id == "hammer"
	var info: Dictionary = world.item(hand.id)
	return int(info.get("tool_type", 0)) == types.get(tool, -1) and int(info.get("tool_tier", 1)) >= min_tier


static func equip_tool(world, player: Dictionary, tool: String, min_tier: int = 1) -> bool:
	if has_tool(world, player, tool, min_tier):
		return true
	var types := {"axe": 1, "pickaxe": 2, "shovel": 3}
	var target_type := int(types.get(tool, -1))
	if target_type < 0:
		return false
	var inv = world.inventory(player)
	var best_idx := -1
	var best_tier := -1
	for i in inv.slots.size():
		var slot: Dictionary = inv.slots[i]
		if slot.is_empty():
			continue
		var info: Dictionary = world.item(slot.id)
		var slot_tier := int(info.get("tool_tier", 1))
		if int(info.get("tool_type", 0)) == target_type and slot_tier >= min_tier and slot_tier > best_tier:
			best_tier = slot_tier
			best_idx = i
	if best_idx < 0:
		return false
	var old_hand: Dictionary = inv.equipment.get("hand", {})
	inv.equipment["hand"] = inv.slots[best_idx]
	inv.slots[best_idx] = old_hand
	player.inventory = inv.to_dict()
	return true


static func wear_hand(player: Dictionary, amount: int) -> void:
	var hand: Dictionary = player.inventory.equipment.get("hand", {})
	if hand.is_empty() or int(hand.get("durability", 0)) <= 0:
		return
	hand.durability -= amount
	if hand.durability <= 0:
		player.inventory.equipment.hand = {}


## Damages a player. Body armour absorbs 40%; a blow (wear_armor) also costs it one durability,
## while damage over time (a leech draining, burning) does not wear it down.
static func hurt(world, player: Dictionary, amount: float, wear_armor: bool = true) -> void:
	if player.ghost:
		return
	var armor: Dictionary = player.inventory.equipment.get("body", {})
	if not armor.is_empty():
		amount *= 0.6
	if not armor.is_empty() and wear_armor:
		armor.durability = int(armor.get("durability", 0)) - 1
		if armor.durability <= 0:
			player.inventory.equipment.body = {}
	var stats = world.stats(player)
	stats.damage(amount)
	player.stats = stats.to_dict()
	player.hit_flash = 0.2
	if player.stats.health <= 0:
		world.life.die(world, player)
