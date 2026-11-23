extends VBoxContainer

signal action(verb: String, args: Dictionary)
const W = preload("res://ui/demo/demo_widgets.gd")
var target: Dictionary = {}
var selected_slot := 0

func refresh(entity: Dictionary) -> void:
	target = entity
	W.clear(self)
	if entity.is_empty():
		W.label(self, "DEMO_TARGET_HINT")
		return
	var name_label := W.label(self, "WORLD_" + String(entity.get("kind", "")).to_upper())
	if entity.get("collection", "") == "drops": name_label.text = W.item_name(String(entity.get("id", entity.get("item", ""))))
	W.label(self, "DEMO_SELECTED_SLOT").text += " %d" % (selected_slot + 1)
	var kind := String(entity.get("kind", ""))
	if kind == "player":
		name_label.text = String(entity.get("name", "")) + (" — " + tr("DEMO_GHOST") if entity.get("ghost", false) else "")
		if entity.get("ghost", false):
			W.button(self, "DEMO_REVIVE", func(): action.emit("revive", {"peer_id": int(entity.uid)}))
		return
	var cooking := kind in ["cooking_pot", "pot", "alchemy_furnace", "alchemy", "furnace"]
	if cooking:
		var ingredients: Array = entity.get("ingredients", [])
		for i in 4:
			W.label(self, "DEMO_INGREDIENT").text += " %d: %s" % [i + 1, W.item_name(String(ingredients[i])) if i < ingredients.size() else tr("DEMO_EMPTY")]
		_button("DEMO_INSERT", "insert", {"slot": selected_slot})
		if "alchemy" in kind or kind == "furnace":
			W.label(self, "DEMO_SOLVENT").text += ": " + W.item_name(String(entity.get("solvent", "")))
			_button("DEMO_ADD_SOLVENT", "insert", {"slot": selected_slot, "solvent": true})
		_button("DEMO_COOK", "cook")
		W.label(self, "DEMO_REMAINING").text += " %.0f" % float(entity.get("remaining", 0))
		if not String(entity.get("output", "")).is_empty():
			W.label(self, "DEMO_OUTPUT").text += ": " + W.item_name(entity.output)
		_button("DEMO_TAKE", "take")
	elif kind in ["chest", "resurrection_altar"]:
		if kind == "resurrection_altar": _button("DEMO_REVIVE", "revive")
		_button("DEMO_CHEST_PUT", "chest_put", {"slot": selected_slot})
		var slots: Array = entity.get("slots", [])
		for i in slots.size():
			if slots[i].is_empty(): continue
			var b := W.button(self, "DEMO_CHEST_TAKE", func(): action.emit("chest_take", {"uid": target.uid, "slot": i}))
			b.text += " " + W.item_name(String(slots[i].get("id", ""))) + " ×" + str(slots[i].get("count", 0))
	elif kind in ["spring", "spirit_spring", "qingmu_spring", "farm", "herb_farm"]:
		var modes := ["fill", "drink", "bathe"] if "spring" in kind else ["water", "fertilize"]
		for mode in modes:
			_button("DEMO_WATER_" + mode.to_upper(), "water", {"mode": mode})
		if "farm" in kind:
			_button("DEMO_PLANT", "plant", {"slot": selected_slot})
			_button("DEMO_TAKE", "water", {"mode": "harvest"})
	elif kind in ["campfire", "fire_pit", "firepit"]:
		W.label(self, "DEMO_FUEL").text += " %.0f" % float(entity.get("fuel", 0))
		_button("DEMO_ADD_FUEL", "fuel", {"slot": selected_slot})
		_button("DEMO_ROAST", "roast", {"slot": selected_slot})
	else:
		for verb in ["pickup", "work", "attack", "revive"]:
			_button("DEMO_" + verb.to_upper(), verb)

func _button(key: String, verb: String, args: Dictionary = {}) -> void:
	W.button(self, key, func():
		var payload := args.duplicate()
		payload.uid = target.get("uid", -1)
		action.emit(verb, payload))
