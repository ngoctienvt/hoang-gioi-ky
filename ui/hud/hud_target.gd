extends VBoxContainer
## Target Inspector card showing contextual info, progress/fuel bars, and actions.

signal action(verb: String, args: Dictionary)
signal open_trade(npc: Dictionary)
signal open_request(npc: Dictionary)

const W = preload("res://ui/hud/hud_widgets.gd")
const UITheme = preload("res://ui/theme/ui_theme.gd")

var target: Dictionary = {}
var selected_slot := 0
var teleports: Array = []


func _ready() -> void:
	add_theme_constant_override("separation", 6)


func refresh(entity: Dictionary) -> void:
	target = entity
	W.clear(self)
	if entity.is_empty():
		W.label(self, "UI_TARGET_HINT")
		return

	var kind := String(entity.get("kind", ""))
	var name_lbl := W.label(self, "WORLD_" + kind.to_upper())
	if entity.get("collection", "") == "drops":
		name_lbl.text = W.item_name(String(entity.get("id", entity.get("item", ""))))
	name_lbl.theme_type_variation = &"LabelHeading"

	var slot_badge := Label.new()
	slot_badge.text = "%s %d" % [tr("UI_SELECTED_SLOT"), selected_slot + 1]
	slot_badge.add_theme_font_size_override("font_size", 11)
	slot_badge.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
	add_child(slot_badge)

	W.divider(self)

	if kind == "player":
		name_lbl.text = String(entity.get("name", "")) + (" — " + tr("UI_GHOST") if entity.get("ghost", false) else "")
		if entity.get("ghost", false):
			W.button(self, "UI_REVIVE", func(): action.emit("revive", {"peer_id": int(entity.uid)}), "ButtonPrimary")
		return

	var cooking := kind in ["cooking_pot", "pot", "alchemy_furnace", "alchemy_furnace_t2", "alchemy", "furnace"]
	if cooking:
		var ingredients: Array = entity.get("ingredients", [])
		for i in 4:
			var ing_lbl := Label.new()
			ing_lbl.text = "%s %d: %s" % [tr("UI_INGREDIENT"), i + 1, W.item_name(String(ingredients[i])) if i < ingredients.size() else tr("UI_EMPTY")]
			ing_lbl.add_theme_font_size_override("font_size", 12)
			add_child(ing_lbl)
		_button("UI_INSERT", "insert", {"slot": selected_slot})
		if "alchemy" in kind or kind == "furnace":
			var sol := Label.new()
			sol.text = "%s: %s" % [tr("UI_SOLVENT"), W.item_name(String(entity.get("solvent", "")))]
			sol.add_theme_font_size_override("font_size", 12)
			add_child(sol)
			_button("UI_ADD_SOLVENT", "insert", {"slot": selected_slot, "solvent": true})
		_button("UI_COOK", "cook", {}, "ButtonPrimary")
		var rem_lbl := Label.new()
		rem_lbl.text = "%s %.0fs" % [tr("UI_REMAINING"), float(entity.get("remaining", 0))]
		rem_lbl.add_theme_font_size_override("font_size", 12)
		add_child(rem_lbl)
		if not String(entity.get("output", "")).is_empty():
			var out_lbl := Label.new()
			out_lbl.text = "%s: %s" % [tr("UI_OUTPUT"), W.item_name(entity.output)]
			out_lbl.add_theme_color_override("font_color", UITheme.TEXT_GOOD)
			add_child(out_lbl)
		_button("UI_TAKE", "take")
	elif kind in ["chest", "talisman_chest", "ice_cellar", "resurrection_altar"]:
		if kind == "resurrection_altar":
			_button("UI_REVIVE", "revive", {}, "ButtonPrimary")
		_button("UI_CHEST_PUT", "chest_put", {"slot": selected_slot}, "ButtonPrimary")
		var slots: Array = entity.get("slots", [])
		for i in slots.size():
			if slots[i].is_empty():
				continue
			var b := W.button(self, "UI_CHEST_TAKE", func(): action.emit("chest_take", {"uid": target.uid, "slot": i}))
			b.text += " " + W.item_name(String(slots[i].get("id", ""))) + " ×" + str(slots[i].get("count", 0))
	elif kind == "water_array":
		_button("UI_INSERT", "insert", {"slot": selected_slot}, "ButtonPrimary")
	elif kind == "light_pillar" or kind.begins_with("puppet_"):
		_fuel_bar(float(entity.get("fuel", 0)), 100.0)
		_button("UI_ADD_FUEL", "fuel", {"slot": selected_slot}, "ButtonPrimary")
	elif kind == "guest_altar":
		_button("UI_INVITE_MERCHANT", "invite_guest", {"guest_type": "merchant"})
		_button("UI_INVITE_WANDERER", "invite_guest", {"guest_type": "wanderer"})
	elif kind == "altar":
		_button("UI_OFFER_ALTAR", "offer_altar", {"slot": selected_slot})
		_button("UI_SUMMON_BOSS", "summon_boss", {}, "ButtonDanger")
	elif kind == "secret_realm_portal":
		_button("UI_ENTER_REALM", "enter_secret_realm", {}, "ButtonPrimary")
	elif kind == "secret_realm_exit":
		_button("UI_EXIT_REALM", "exit_secret_realm", {}, "ButtonPrimary")
	elif kind == "realm_switch":
		_button("UI_ACTIVATE_SWITCH", "activate_switch", {}, "ButtonPrimary")
	elif kind == "realm_chest":
		_button("UI_CLAIM_VAULT", "claim_vault", {}, "ButtonPrimary")
	elif kind == "awakening_altar":
		_button("UI_START_AWAKENING", "start_awakening", {}, "ButtonPrimary")
	elif kind == "merchant":
		W.button(self, "UI_TRADE", func(): open_trade.emit(target), "ButtonPrimary")
	elif kind == "wanderer":
		W.button(self, "UI_FULFILL_REQUEST", func(): open_request.emit(target), "ButtonPrimary")
	elif kind == "lightning_rod":
		var ch_lbl := Label.new()
		ch_lbl.text = tr("UI_CHARGES") % int(entity.get("charges", 0))
		add_child(ch_lbl)
		if int(entity.get("charges", 0)) > 0:
			_button("UI_TAKE", "take", {}, "ButtonPrimary")
	elif kind in ["spring", "spirit_spring", "qingmu_spring", "farm", "herb_farm"]:
		if entity.get("frozen", false):
			var fr_lbl := W.label(self, "UI_FROZEN")
			fr_lbl.add_theme_color_override("font_color", UITheme.TEXT_WARN)
			_button("UI_WORK", "work", {}, "ButtonPrimary")
			return
		var modes := ["fill", "drink", "bathe"] if "spring" in kind else ["water", "fertilize"]
		for mode in modes:
			_button("UI_WATER_" + mode.to_upper(), "water", {"mode": mode})
		if "farm" in kind:
			_button("UI_PLANT", "plant", {"slot": selected_slot})
			_button("UI_TAKE", "water", {"mode": "harvest"}, "ButtonPrimary")
	elif kind in ["campfire", "fire_pit", "firepit"]:
		_fuel_bar(float(entity.get("fuel", 0)), 100.0)
		_button("UI_ADD_FUEL", "fuel", {"slot": selected_slot}, "ButtonPrimary")
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


func _fuel_bar(val: float, max_val: float) -> void:
	var lbl := Label.new()
	lbl.text = "%s %.0f" % [tr("UI_FUEL"), val]
	lbl.add_theme_font_size_override("font_size", 12)
	add_child(lbl)
	var bar := ProgressBar.new()
	bar.max_value = max_val
	bar.value = clampf(val, 0.0, max_val)
	bar.custom_minimum_size = Vector2(210, 8)
	bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("d88a3c")
	fill.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("fill", fill)
	add_child(bar)


func _button(key: String, verb: String, args: Dictionary = {}, variation: String = "") -> void:
	W.button(self, key, func():
		var payload := args.duplicate()
		payload.uid = target.get("uid", -1)
		action.emit(verb, payload)
	, variation)
