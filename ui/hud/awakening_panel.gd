extends PanelContainer

signal action(verb: String, args: Dictionary)

const W = preload("res://ui/hud/hud_widgets.gd")
const WorldAbilities = preload("res://world/simulation/world_abilities.gd")
const WorldSkills = preload("res://world/simulation/world_skills.gd")

var content: VBoxContainer
var selected_slot := 0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	position = Vector2(-240, -230)
	custom_minimum_size = Vector2(480, 460)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(460, 440)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	hide()


func refresh(state: Dictionary, player: Dictionary, slot_idx: int) -> void:
	selected_slot = slot_idx
	if not visible or player.is_empty():
		return
	W.clear(content)
	var header := HBoxContainer.new()
	content.add_child(header)
	W.label(header, "UI_AWAKENING_TITLE")
	W.button(header, "UI_CLOSE", func(): hide())

	var tier := int(player.get("awakening_tier", 0))
	var pts := int(player.get("skill_points", 0))
	var tier_lbl := W.label(content, "")
	tier_lbl.text = tr("UI_AWAKENING_TIER") % [tier, pts]

	for r in state.get("rituals", []):
		if int(r.get("owner_uid", 0)) == int(player.get("uid", -1)):
			var rl := W.label(content, "")
			rl.text = tr("UI_RITUAL_PROGRESS") % [int(r.get("wave", 1)), 3, ceili(float(r.get("wave_timer", 0.0)))]

	var cdef = WorldAbilities.character_def(player)
	if cdef != null:
		W.label(content, "UI_SKILL_TREE")
		var unlocked: Array = player.get("skills", [])
		var nodes := WorldSkills.skills_for_tree(String(cdef.skill_tree_id))
		for s in nodes:
			var sid := String(s.id)
			var is_unlocked := sid in unlocked
			var excluded := false
			for ex in s.excludes:
				if String(ex) in unlocked:
					excluded = true
					break
			var row := HBoxContainer.new()
			content.add_child(row)
			var info := Label.new()
			info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			info.text = "[T%d] %s — %s" % [int(s.tier), tr(s.name_key), tr(s.desc_key)]
			row.add_child(info)
			var b := Button.new()
			if is_unlocked:
				b.text = tr("UI_UNLOCKED")
				b.disabled = true
			elif excluded:
				b.text = tr("UI_EXCLUDED")
				b.disabled = true
			else:
				b.text = tr("UI_UNLOCK")
				b.disabled = pts < 1 or tier < int(s.tier)
				b.pressed.connect(func(): action.emit("unlock_skill", {"skill_id": sid}))
			row.add_child(b)

	W.label(content, "UI_IMPRINTS")
	var max_imp := mini(3, tier)
	var imprints: Array = player.get("imprints", [])
	var imp_info := W.label(content, "")
	imp_info.text = tr("UI_IMPRINT_SLOTS") % [imprints.size(), max_imp]
	for i in imprints.size():
		var imp_id := str(imprints[i])
		var row := HBoxContainer.new()
		content.add_child(row)
		var lbl := Label.new()
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.text = tr("ITEM_" + imp_id.to_upper())
		row.add_child(lbl)
		var idx := i
		W.button(row, "UI_UNEQUIP_IMPRINT", func(): action.emit("unequip_imprint", {"index": idx}))
	if imprints.size() < max_imp:
		W.button(content, "UI_EQUIP_IMPRINT", func(): action.emit("equip_imprint", {"slot": selected_slot}))
