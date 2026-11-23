extends HBoxContainer
## Compact square ability tiles [Q][E][R] with icon hook, cooldown wipe overlay, and hotkey badge.

signal action(verb: String, args: Dictionary)

const UITheme = preload("res://ui/theme/ui_theme.gd")
const WorldAbilities = preload("res://world/simulation/world_abilities.gd")
const PuppeteerCraft = preload("res://world/simulation/traits/puppeteer_craft.gd")
const BoundaryDao = preload("res://world/simulation/traits/boundary_dao.gd")
const BeastRage = preload("res://world/simulation/traits/beast_rage.gd")

const HOTKEYS := ["Q", "E", "R"]
var buttons: Array[AbilityTile] = []
var built_char := ""
var selected_slot := 0
var indicator_text := ""


func _ready() -> void:
	add_theme_constant_override("separation", 6)


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
		var tile := buttons[i]
		var cd := float(cds.get(String(adef.id), 0.0))
		if String(adef.id) == "beast":
			cd = maxf(cd, float(player.get("ability_cd", 0.0)))
		elif String(adef.id) == "sense":
			cd = maxf(cd, float(player.get("sense_cd", 0.0)))
		var max_cd := maxf(1.0, float(adef.cooldown))
		tile.set_cooldown(cd, max_cd)
	indicator_text = _indicator_text(cid, state, player)


func _rebuild(cid: String, cdef: CharacterDef) -> void:
	built_char = cid
	for b in buttons:
		remove_child(b)
		b.queue_free()
	buttons.clear()
	for i in cdef.abilities.size():
		var adef: AbilityDef = cdef.abilities[i]
		var ab_id := String(adef.id)
		var key_lbl: String = HOTKEYS[i] if i < HOTKEYS.size() else ""
		var tile := AbilityTile.new()
		tile.configure(ab_id, key_lbl, tr(adef.name_key), tr(adef.desc_key), _resolve_ability_icon(ab_id))
		tile.pressed.connect(func():
			var args: Dictionary = {"name": ab_id}
			if ab_id == "devour":
				args["slot"] = selected_slot
			action.emit("ability", args)
		)
		add_child(tile)
		buttons.append(tile)


func _resolve_ability_icon(ab_id: String) -> Texture2D:
	var candidates := [
		"res://assets/ui/illustrations/ability-%s.png" % ab_id,
		"res://assets/ui/illustrations/ability-%s.png" % ab_id.replace("_", "-"),
	]
	for path in candidates:
		if ResourceLoader.exists(path):
			var tex := load(path)
			if tex is Texture2D:
				return tex
	return null


func _indicator_text(cid: String, state: Dictionary, player: Dictionary) -> String:
	match cid:
		"beast_bloodline":
			var txt := tr("UI_RAGE_METER") % int(player.get("rage", 0.0))
			if BeastRage.is_full_moon({"state": state}):
				txt += " • " + tr("UI_FULL_MOON")
			return txt
		"devourer":
			return tr("UI_POISON_METER") % [int(player.get("poison", 0.0)), int(player.get("poison_threshold", 150.0))]
		"puppeteer":
			var count := PuppeteerCraft.guard_puppets({"state": state}, -int(player.get("uid", -1))).size()
			return tr("UI_PUPPET_COUNT") % count
		"yin_yang":
			var dao := int(player.get("stats", {}).get("dao", 50.0))
			var st := tr("UI_BOUNDARY_OK") if BoundaryDao.in_boundary(player) else tr("UI_BOUNDARY_OUT")
			return tr("UI_BOUNDARY_METER") % [dao, st]
		_:
			return ""


class AbilityTile extends Button:
	var hotkey := ""
	var title := ""
	var monogram := ""
	var icon_tex: Texture2D
	var cd_rem := 0.0
	var cd_max := 1.0
	var _hovered := false

	func configure(ab_id: String, key_lbl: String, ab_name: String, ab_desc: String, tex: Texture2D) -> void:
		hotkey = key_lbl
		title = ab_name
		icon_tex = tex
		monogram = _make_monogram(ab_name, ab_id)
		custom_minimum_size = Vector2(48, 48)
		focus_mode = Control.FOCUS_NONE
		text = ""
		tooltip_text = "[%s] %s\n%s" % [hotkey, ab_name, ab_desc]
		mouse_entered.connect(func(): _hovered = true; queue_redraw())
		mouse_exited.connect(func(): _hovered = false; queue_redraw())

	func set_cooldown(rem: float, max_val: float) -> void:
		var changed := not is_equal_approx(cd_rem, rem)
		cd_rem = rem
		cd_max = maxf(0.1, max_val)
		disabled = cd_rem > 0.1
		if changed:
			queue_redraw()

	func _make_monogram(ab_name: String, ab_id: String) -> String:
		var words := ab_name.strip_edges().split(" ", false)
		if words.size() >= 2:
			return (words[0].left(1) + words[1].left(1)).to_upper()
		if not ab_name.is_empty():
			return ab_name.left(2).to_upper()
		return ab_id.left(2).to_upper()

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		var bg := Color(0.08, 0.125, 0.115, 0.95) if not _hovered else Color(0.13, 0.20, 0.18, 0.98)
		draw_rect(rect, bg, true)

		if icon_tex != null:
			draw_texture_rect(icon_tex, Rect2(5, 5, size.x - 10, size.y - 10), false)
		else:
			draw_circle(size * 0.5, 17.0, Color(0.13, 0.22, 0.195, 0.9))
			draw_arc(size * 0.5, 17.0, 0.0, TAU, 28, UITheme.BORDER_GOLD_DIM, 1.2, true)
			var font := get_theme_font("font")
			var m_sz := font.get_string_size(monogram, HORIZONTAL_ALIGNMENT_LEFT, -1, 14)
			draw_string(font, Vector2((size.x - m_sz.x) * 0.5, size.y * 0.5 + 5.0), monogram, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, UITheme.TEXT_ACCENT)

		if cd_rem > 0.1:
			var frac := clampf(cd_rem / cd_max, 0.0, 1.0)
			draw_rect(Rect2(0, size.y * (1.0 - frac), size.x, size.y * frac), Color(0.02, 0.03, 0.03, 0.72), true)
			var font := get_theme_font("font")
			var cd_txt := "%ds" % ceili(cd_rem)
			var cd_sz := font.get_string_size(cd_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 15)
			draw_string_outline(font, Vector2((size.x - cd_sz.x) * 0.5, size.y * 0.5 + 5.0), cd_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, 3, Color(0.01, 0.02, 0.02, 0.95))
			draw_string(font, Vector2((size.x - cd_sz.x) * 0.5, size.y * 0.5 + 5.0), cd_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, UITheme.TEXT_PRIMARY)

		draw_rect(rect, UITheme.BORDER_GOLD if _hovered and cd_rem <= 0.1 else UITheme.BORDER_GOLD_DIM, false, 1.5)

		if not hotkey.is_empty():
			var font := get_theme_font("font")
			draw_rect(Rect2(2, 2, 16, 14), Color(0.03, 0.05, 0.05, 0.88), true)
			draw_string(font, Vector2(5, 13), hotkey, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, UITheme.TEXT_ACCENT)
