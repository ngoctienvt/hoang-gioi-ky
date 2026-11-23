class_name InventoryComponent
extends RefCounted

var slots: Array[Dictionary] = []
var equipment: Dictionary = {"hand": {}, "body": {}, "head": {}}

func _init() -> void:
	for i in 15:
		slots.append({})

func add_item(id: String, count: int = 1, extra: Dictionary = {}) -> int:
	var item = ItemDB.get_item(id)
	if count <= 0:
		return 0
	if item == null:
		return count
	var remaining = count
	var metadata = _stack_metadata(extra)
	for slot in slots:
		if slot.get("id", "") == id and item.max_durability == 0 and _stack_metadata(slot) == metadata:
			var added = mini(remaining, item.max_stack - int(slot.count))
			slot.count += added
			remaining -= added
			if remaining == 0:
				return 0
	for i in slots.size():
		if slots[i].is_empty():
			var added = mini(remaining, item.max_stack)
			var slot = extra.duplicate(true)
			slot.id = id
			slot.count = added
			slot.durability = clampi(int(extra.get("durability", item.max_durability)), 0, item.max_durability)
			slots[i] = slot
			remaining -= added
			if remaining == 0:
				break
	return remaining

func _stack_metadata(slot: Dictionary) -> Dictionary:
	var metadata = slot.duplicate(true)
	for key in ["id", "count", "durability"]:
		metadata.erase(key)
	return metadata

func count_item(id: String) -> int:
	var count = 0
	for slot in slots:
		if slot.get("id", "") == id:
			count += int(slot.count)
	return count

func remove_item(id: String, count: int) -> bool:
	if count < 0 or count_item(id) < count:
		return false
	var remaining = count
	for i in slots.size():
		if slots[i].get("id", "") == id:
			var taken = mini(remaining, int(slots[i].count))
			slots[i].count -= taken
			remaining -= taken
			if slots[i].count == 0:
				slots[i] = {}
	return true

func craft(recipe: RecipeDef, tier: int) -> bool:
	if recipe == null or recipe.result == null or tier < recipe.tier:
		return false
	for id in recipe.ingredients:
		if count_item(String(id)) < recipe.ingredients[id]:
			return false
	var previous = to_dict()
	for id in recipe.ingredients:
		remove_item(String(id), recipe.ingredients[id])
	if add_item(String(recipe.result.id), recipe.result_count) > 0:
		from_dict(previous)
		return false
	return true

func use_durability(index: int, amount: int = 1) -> bool:
	if index < 0 or index >= slots.size() or slots[index].is_empty() or amount <= 0:
		return false
	var item = ItemDB.get_item(slots[index].id)
	if item == null or item.max_durability == 0:
		return false
	slots[index].durability -= amount
	if slots[index].durability <= 0:
		slots[index] = {}
	return true

func split_stack(source: int, target: int, count: int) -> bool:
	if source < 0 or source >= 15 or target < 0 or target >= 15 or source == target:
		return false
	if slots[source].is_empty() or not slots[target].is_empty() or count <= 0 or count >= int(slots[source].count):
		return false
	slots[target] = slots[source].duplicate(true)
	slots[target].count = count
	slots[source].count -= count
	return true

func swap_slots(a: int, b: int) -> bool:
	if a < 0 or a >= 15 or b < 0 or b >= 15:
		return false
	var temp = slots[a]
	slots[a] = slots[b]
	slots[b] = temp
	return true

func to_dict() -> Dictionary:
	return {"slots": slots.duplicate(true), "equipment": equipment.duplicate(true)}

func from_dict(state: Dictionary) -> void:
	for i in 15:
		slots[i] = {}
	var raw_slots = state.get("slots", [])
	if raw_slots is Array:
		for i in mini(15, raw_slots.size()):
			slots[i] = _validated_slot(raw_slots[i])
	var raw_equipment = state.get("equipment", {})
	if raw_equipment is Dictionary:
		for key in equipment:
			equipment[key] = _validated_slot(raw_equipment.get(key, {}))

func _validated_slot(raw: Variant) -> Dictionary:
	if not raw is Dictionary or not raw.has("id") or not raw.get("id") is String:
		return {}
	var item = ItemDB.get_item(raw.id)
	if item == null or not (raw.get("count", 0) is float or raw.get("count", 0) is int):
		return {}
	var count = clampi(int(raw.count), 0, item.max_stack)
	if count == 0:
		return {}
	var result = raw.duplicate(true)
	result.count = count
	result.durability = clampi(int(raw.get("durability", item.max_durability)), 0, item.max_durability)
	return result
