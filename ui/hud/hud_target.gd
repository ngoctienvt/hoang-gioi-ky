extends VBoxContainer

signal action(verb: String, args: Dictionary)
signal open_trade(npc: Dictionary)
signal open_request(npc: Dictionary)
const W = preload("res://ui/hud/hud_widgets.gd")
var target: Dictionary = {}
var selected_slot := 0
var teleports: Array = []

func refresh(entity: Dictionary) -> void:
	target = entity
	W.clear(self)
	if entity.is_empty():
		W.label(self, "UI_TARGET_HINT")
		return
	var name_label := W.label(self, "WORLD_" + String(entity.get("kind", "")).to_upper())
	if entity.get("collection", "") == "drops": name_label.text = W.item_name(String(entity.get("id", entity.get("item", ""))))
	W.label(self, "UI_SELECTED_SLOT").text += " %d" % (selected_slot + 1)
	var kind := String(entity.get("kind", ""))
	if kind == "player":
		name_label.text = String(entity.get("name", "")) + (" — " + tr("UI_GHOST") if entity.get("ghost", false) else "")
		if entity.get("ghost", false):
			W.button(self, "UI_REVIVE", func(): action.emit("revive", {"peer_id": int(entity.uid)}))
		return
	var cooking := kind in ["cooking_pot", "pot", "alchemy_furnace", "alchemy_furnace_t2", "alchemy", "furnace"]
	if cooking:
		var ingredients: Array = entity.get("ingredients", [])
		for i in 4:
			W.label(self, "UI_INGREDIENT").text += " %d: %s" % [i + 1, W.item_name(String(ingredients[i])) if i < ingredients.size() else tr("UI_EMPTY")]
		_button("UI_INSERT", "insert", {"slot": selected_slot})
		if "alchemy" in kind or kind == "furnace":
			W.label(self, "UI_SOLVENT").text += ": " + W.item_name(String(entity.get("solvent", "")))
			_button("UI_ADD_SOLVENT", "insert", {"slot": selected_slot, "solvent": true})
		_button("UI_COOK", "cook")
		W.label(self, "UI_REMAINING").text += " %.0f" % float(entity.get("remaining", 0))
		if not String(entity.get("output", "")).is_empty():
			W.label(self, "UI_OUTPUT").text += ": " + W.item_name(entity.output)
		_button("UI_TAKE", "take")
	elif kind in ["chest", "talisman_chest", "ice_cellar", "resurrection_altar"]:
		if kind == "resurrection_altar": _button("UI_REVIVE", "revive")
		_button("UI_CHEST_PUT", "chest_put", {"slot": selected_slot})
		var slots: Array = entity.get("slots", [])
		for i in slots.size():
			if slots[i].is_empty(): continue
			var b := W.button(self, "UI_CHEST_TAKE", func(): action.emit("chest_take", {"uid": target.uid, "slot": i}))
			b.text += " " + W.item_name(String(slots[i].get("id", ""))) + " ×" + str(slots[i].get("count", 0))
	elif kind == "water_array":
		_button("UI_INSERT", "insert", {"slot": selected_slot})
	elif kind == "light_pillar" or kind.begins_with("puppet_"):
		W.label(self, "UI_FUEL").text += " %.0f" % float(entity.get("fuel", 0))
		_button("UI_ADD_FUEL", "fuel", {"slot": selected_slot})
	elif kind == "guest_altar":
		_button("UI_INVITE_MERCHANT", "invite_guest", {"guest_type": "merchant"})
		_button("UI_INVITE_WANDERER", "invite_guest", {"guest_type": "wanderer"})
	elif kind == "altar":
		_button("UI_OFFER_ALTAR", "offer_altar", {"slot": selected_slot})
		_button("UI_SUMMON_BOSS", "summon_boss")
	elif kind == "secret_realm_portal":
		_button("UI_ENTER_REALM", "enter_secret_realm")
	elif kind == "secret_realm_exit":
		_button("UI_EXIT_REALM", "exit_secret_realm")
	elif kind == "realm_switch":
		_button("UI_ACTIVATE_SWITCH", "activate_switch")
	elif kind == "realm_chest":
		_button("UI_CLAIM_VAULT", "claim_vault")
	elif kind == "awakening_altar":
		_button("UI_START_AWAKENING", "start_awakening")
	elif kind == "merchant":
		W.button(self, "UI_TRADE", func(): open_trade.emit(target))
	elif kind == "wanderer":
		W.button(self, "UI_FULFILL_REQUEST", func(): open_request.emit(target))
	elif kind == "lightning_rod":
		W.label(self, "UI_CHARGES").text = tr("UI_CHARGES") % int(entity.get("charges", 0))
		if int(entity.get("charges", 0)) > 0:
			_button("UI_TAKE", "take")
	elif kind in ["spring", "spirit_spring", "qingmu_spring", "farm", "herb_farm"]:
		if entity.get("frozen", false):
			W.label(self, "UI_FROZEN")
			_button("UI_WORK", "work")
			return
		var modes := ["fill", "drink", "bathe"] if "spring" in kind else ["water", "fertilize"]
		for mode in modes:
			_button("UI_WATER_" + mode.to_upper(), "water", {"mode": mode})
		if "farm" in kind:
			_button("UI_PLANT", "plant", {"slot": selected_slot})
			_button("UI_TAKE", "water", {"mode": "harvest"})
	elif kind in ["campfire", "fire_pit", "firepit"]:
		W.label(self, "UI_FUEL").text += " %.0f" % float(entity.get("fuel", 0))
		_button("UI_ADD_FUEL", "fuel", {"slot": selected_slot})
		_button("UI_ROAST", "roast", {"slot": selected_slot})
	elif kind == "teleport_array":
		if str(entity.get("state", "dormant")) != "active":
			W.label(self, "UI_TELEPORT_DORMANT")
		else:
			W.label(self, "UI_TELEPORT_TO")
			for tp in teleports:
				if int(tp.get("uid", -1)) == int(entity.get("uid", -2)):
					continue
				if str(tp.get("state", "dormant")) != "active":
					continue
				var dest_uid := int(tp.uid)
				var bname := tr("BIOME_" + str(tp.get("biome", "")).to_upper())
				var btn := Button.new()
				btn.text = bname + " " + tr("UI_TELEPORT_COST")
				btn.pressed.connect(func(): action.emit("teleport", {"uid": int(target.uid), "target_uid": dest_uid}))
				add_child(btn)
	else:
		for verb in ["pickup", "work", "attack", "revive"]:
			_button("UI_" + verb.to_upper(), verb)
		_button("UI_THROW_TALISMAN", "throw_talisman", {"slot": selected_slot})
		_button("UI_CAPTURE_BEAST", "capture_beast")

func _button(key: String, verb: String, args: Dictionary = {}) -> void:
	W.button(self, key, func():
		var payload := args.duplicate()
		payload.uid = target.get("uid", -1)
		action.emit(verb, payload))
