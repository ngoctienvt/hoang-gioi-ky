extends HBoxContainer

signal action(verb: String, args: Dictionary)

const WorldAbilities = preload("res://world/simulation/world_abilities.gd")
const PuppeteerCraft = preload("res://world/simulation/traits/puppeteer_craft.gd")
const BoundaryDao = preload("res://world/simulation/traits/boundary_dao.gd")
const BeastRage = preload("res://world/simulation/traits/beast_rage.gd")

const HOTKEYS := ["Q", "E", "R"]
var buttons: Array[Button] = []
var indicator: Label
var built_char := ""
var selected_slot := 0


func _ready() -> void:
	indicator = Label.new()
	indicator.add_theme_font_size_override("font_size", 12)
	add_child(indicator)


func refresh(state: Dictionary, player: Dictionary, slot_index: int = 0) -> void:
	selected_slot = slot_index
	if player.is_empty():
		return
	var cid := WorldAbilities.effective_character_id(player)
	var cdef := WorldAbilities.get_character(cid)
	if cdef == null:
		return
	if cid != built_char:
		_rebuild(cid, cdef)
	var cds: Dictionary = player.get("ability_cds", {})
	for i in buttons.size():
		if i >= cdef.abilities.size():
			continue
		var adef: AbilityDef = cdef.abilities[i]
		var btn := buttons[i]
		var cd := float(cds.get(String(adef.id), 0.0))
		if String(adef.id) == "beast":
			cd = maxf(cd, float(player.get("ability_cd", 0.0)))
		elif String(adef.id) == "sense":
			cd = maxf(cd, float(player.get("sense_cd", 0.0)))
		var key_lbl: String = HOTKEYS[i] if i < HOTKEYS.size() else ""
		var label_text := "[%s] %s" % [key_lbl, tr(adef.name_key)]
		if cd > 0.1:
			label_text += " (%ds)" % ceili(cd)
		btn.text = label_text
		btn.disabled = cd > 0.1
	indicator.text = _indicator_text(cid, state, player)


func _rebuild(cid: String, cdef: CharacterDef) -> void:
	built_char = cid
	for b in buttons:
		remove_child(b)
		b.queue_free()
	buttons.clear()
	for i in cdef.abilities.size():
		var adef: AbilityDef = cdef.abilities[i]
		var btn := Button.new()
		btn.focus_mode = Control.FOCUS_NONE
		btn.tooltip_text = tr(adef.desc_key)
		var ab_id := String(adef.id)
		if ab_id == "beast":
			btn.icon = preload("res://assets/ui/illustrations/ability-beast.png")
		elif ab_id == "sense":
			btn.icon = preload("res://assets/ui/illustrations/ability-sense.png")
		if btn.icon != null:
			btn.expand_icon = true
			btn.add_theme_constant_override("icon_max_width", 28)
		btn.pressed.connect(func():
			var args: Dictionary = {"name": ab_id}
			if ab_id == "devour":
				args["slot"] = selected_slot
			action.emit("ability", args)
		)
		add_child(btn)
		move_child(btn, i)
		buttons.append(btn)


func _indicator_text(cid: String, state: Dictionary, player: Dictionary) -> String:
	match cid:
		"beast_bloodline":
			var txt := tr("UI_RAGE_METER") % int(player.get("rage", 0.0))
			if BeastRage.is_full_moon({"state": state}):
				txt += " | " + tr("UI_FULL_MOON")
			return txt
		"devourer":
			return tr("UI_POISON_METER") % [int(player.get("poison", 0.0)), int(player.get("poison_threshold", 150.0))]
		"puppeteer":
			var count := PuppeteerCraft.guard_puppets({"state": state}, -int(player.get("uid", -1))).size()
			return tr("UI_PUPPET_COUNT") % count
		"yin_yang":
			var dao := int(player.get("stats", {}).get("dao", 50.0))
			var status := tr("UI_BOUNDARY_OK") if BoundaryDao.in_boundary(player) else tr("UI_BOUNDARY_OUT")
			return tr("UI_BOUNDARY_METER") % [dao, status]
		_:
			return ""
