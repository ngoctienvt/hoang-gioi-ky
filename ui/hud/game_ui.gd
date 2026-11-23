extends CanvasLayer

signal host_requested(options: Dictionary)
signal join_requested(address: String, player_name: String)
signal action_requested(verb: String, args: Dictionary)
signal leave_requested
signal save_requested

const W = preload("res://ui/hud/hud_widgets.gd")
const UITheme = preload("res://ui/theme/ui_theme.gd")
const Slot = preload("res://ui/hud/hud_slot.gd")
const ModalStack = preload("res://ui/hud/ui_modal_stack.gd")
const ToastFeed = preload("res://ui/hud/hud_toast.gd")
const PauseMenu = preload("res://ui/menu/pause_menu.gd")
const MinimapClass = preload("res://ui/hud/hud_minimap.gd")

var root: Control
var menu: PanelContainer
var menu_backdrop: Control
var game: Control
var modal_stack: ModalStack
var toast: ToastFeed

var equipment: HBoxContainer
var inventory: GridContainer # Hotbar (slots 0..9)
var bag_grid: GridContainer  # Expandable bag (slots 10..29)
var bag_panel: PanelContainer
var bag_btn: Button
var recipes: VBoxContainer
var target_panel: VBoxContainer
var current_target: Dictionary = {}
var selected_slot := 0
var last_signature := ""
var latest_state: Dictionary = {}
var local_id := 1

var radial: Control
var menu_content: VBoxContainer
var target_frame: PanelContainer
var craft_frame: PanelContainer
var rail_buttons: Array[Button] = []
var book_button: Button

var biome_banner_panel: PanelContainer
var biome_banner: Label
var current_biome := ""
var banner_timer := 0.0

var minimap: Control
var minimap_biome_lbl: Label
var world_map_modal: PanelContainer
var world_map_view: Control

var karma_hud: VBoxContainer
var awakening_btn: Button
var awakening_dot: ColorRect

var trade_panel: PanelContainer
var request_panel: PanelContainer
var interact_pill: PanelContainer
var interact_hint: Label
var abilities_hud: HBoxContainer
var meter_pill: PanelContainer
var meter_lbl: Label
var temper_btn: Button
var plant_btn: Button

var char_select: PanelContainer
var awakening_panel: PanelContainer
var boss_hud: PanelContainer
var settings_panel: PanelContainer
var pause_menu: PanelContainer
var tutorial_overlay: PanelContainer
var controls_popover: PanelContainer


func _ready() -> void:
	layer = 20
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = W.theme()
	add_child(root)

	_build_menu_layer()
	_build_game_layer()
	_build_modals()
	show_menu()


func _build_menu_layer() -> void:
	menu_backdrop = preload("res://ui/menu/menu_backdrop.gd").new()
	root.add_child(menu_backdrop)

	menu = PanelContainer.new()
	menu.theme_type_variation = &"PanelModal"
	menu.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	menu.offset_left = 56
	menu.offset_right = 460
	menu.offset_top = -270
	menu.offset_bottom = 270
	root.add_child(menu)

	menu_content = preload("res://ui/menu/main_menu.gd").new()
	menu_content.host_requested.connect(func(options): host_requested.emit(options))
	menu_content.join_requested.connect(func(address, name_value): join_requested.emit(address, name_value))
	menu_content.settings_requested.connect(func():
		if settings_panel:
			settings_panel.open_settings()
			modal_stack.open_modal(settings_panel, true)
	)
	menu.add_child(menu_content)


func _build_game_layer() -> void:
	game = Control.new()
	game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(game)

	# 1. Top-Left: Karma + Awakening/Menu Quick Buttons
	var top_left := VBoxContainer.new()
	top_left.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	top_left.offset_left = 12
	top_left.offset_top = 12
	top_left.offset_right = 228
	top_left.offset_bottom = 140
	top_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_left.add_theme_constant_override("separation", 6)
	game.add_child(top_left)

	var karma_panel := PanelContainer.new()
	karma_panel.theme_type_variation = &"PanelPrimary"
	top_left.add_child(karma_panel)
	karma_hud = preload("res://ui/hud/hud_karma.gd").new()
	karma_panel.add_child(karma_hud)

	var sys_row := HBoxContainer.new()
	sys_row.add_theme_constant_override("separation", 6)
	top_left.add_child(sys_row)

	awakening_btn = W.button(sys_row, "UI_AWAKENING_BTN", func(): _toggle_awakening(), "ButtonSubtle")
	awakening_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	awakening_btn.focus_mode = Control.FOCUS_NONE
	awakening_btn.tooltip_text = W.t("UI_AWAKENING_TITLE", "Thức Tỉnh") + " [K]"
	awakening_dot = ColorRect.new()
	awakening_dot.color = UITheme.TEXT_ACCENT
	awakening_dot.custom_minimum_size = Vector2(7, 7)
	awakening_dot.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	awakening_dot.offset_left = -10
	awakening_dot.offset_top = 4
	awakening_dot.offset_right = -3
	awakening_dot.offset_bottom = 11
	awakening_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	awakening_dot.visible = false
	awakening_btn.add_child(awakening_dot)

	var menu_btn := W.button(sys_row, "", func(): _toggle_pause(), "ButtonSubtle", "☰ Menu")
	menu_btn.focus_mode = Control.FOCUS_NONE
	menu_btn.tooltip_text = "Menu [ESC]"

	# 2. Top-Right: Radial Clock, World Strip & Vitals
	radial = preload("res://ui/hud/hud_radial.gd").new()
	radial.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	radial.offset_left = -258
	radial.offset_right = -12
	radial.offset_top = 10
	radial.offset_bottom = 216
	game.add_child(radial)

	# 3. Top-Center: Boss Bar & Toast Feed
	boss_hud = preload("res://ui/hud/hud_boss.gd").new()
	game.add_child(boss_hud)

	toast = ToastFeed.new()
	root.add_child(toast)

	# 4. Biome Banner (Upper Center Ink Ribbon)
	var banner_center := CenterContainer.new()
	banner_center.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	banner_center.offset_top = 92
	banner_center.offset_bottom = 152
	banner_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game.add_child(banner_center)

	biome_banner_panel = PanelContainer.new()
	biome_banner_panel.theme_type_variation = &"PanelPill"
	biome_banner_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	biome_banner_panel.modulate.a = 0.0
	banner_center.add_child(biome_banner_panel)

	biome_banner = Label.new()
	biome_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	biome_banner.add_theme_font_size_override("font_size", 24)
	biome_banner.add_theme_color_override("font_color", UITheme.TEXT_ACCENT)
	biome_banner_panel.add_child(biome_banner)

	# 5. Center-Left: Crafting Rail & Slide-Out Drawer
	var rail_panel := PanelContainer.new()
	rail_panel.theme_type_variation = &"PanelPrimary"
	rail_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	rail_panel.offset_left = 12
	rail_panel.offset_right = 68
	rail_panel.offset_top = -176
	rail_panel.offset_bottom = 176
	game.add_child(rail_panel)

	var rail := VBoxContainer.new()
	rail.add_theme_constant_override("separation", 4)
	rail_panel.add_child(rail)

	var category_icons := ["tools", "light", "survival", "combat", "buildings", "talismans", "puppets"]
	var keys := ["UI_TOOLS", "UI_LIGHT", "UI_SURVIVAL", "UI_COMBAT", "UI_BUILDINGS", "UI_TALISMANS", "UI_PUPPETS"]
	for i in 7:
		var idx := i
		var cb := W.icon_button(rail, load("res://assets/ui/icons/ui-%s.svg" % category_icons[i]), tr(keys[i]), func():
			if craft_frame.visible and not recipes.wiki and recipes.group == idx:
				_close_craft()
			else:
				recipes.group = idx
				recipes.wiki = false
				_open_craft_panel()
		, Vector2(36, 36))
		cb.focus_mode = Control.FOCUS_NONE
		rail_buttons.append(cb)

	W.divider(rail)

	book_button = W.icon_button(rail, preload("res://assets/ui/icons/ui-book.svg"), tr("UI_BOOK") + " [B]", func(): _toggle_craft(true), Vector2(36, 36))
	book_button.focus_mode = Control.FOCUS_NONE

	craft_frame = PanelContainer.new()
	craft_frame.theme_type_variation = &"PanelPrimary"
	craft_frame.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	craft_frame.offset_left = 76
	craft_frame.offset_right = 408
	craft_frame.offset_top = -220
	craft_frame.offset_bottom = 220
	game.add_child(craft_frame)

	recipes = preload("res://ui/hud/hud_recipes.gd").new()
	recipes.action.connect(_action)
	recipes.close_requested.connect(_close_craft)
	craft_frame.add_child(recipes)
	craft_frame.hide()

	# 6. Bottom-Right: Minimap + Target Inspector (above Minimap)
	var map_frame := PanelContainer.new()
	map_frame.theme_type_variation = &"PanelPrimary"
	map_frame.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	map_frame.offset_left = -202
	map_frame.offset_right = -12
	map_frame.offset_top = -176
	map_frame.offset_bottom = -14
	game.add_child(map_frame)

	var map_col := VBoxContainer.new()
	map_col.add_theme_constant_override("separation", 4)
	map_frame.add_child(map_col)

	var map_head := HBoxContainer.new()
	map_col.add_child(map_head)
	minimap_biome_lbl = Label.new()
	minimap_biome_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	minimap_biome_lbl.add_theme_font_size_override("font_size", 11)
	minimap_biome_lbl.add_theme_color_override("font_color", UITheme.TEXT_ACCENT)
	map_head.add_child(minimap_biome_lbl)
	var expand_btn := W.button(map_head, "", func(): _toggle_world_map(), "ButtonSubtle", "[M]")
	expand_btn.focus_mode = Control.FOCUS_NONE
	expand_btn.add_theme_font_size_override("font_size", 11)
	expand_btn.tooltip_text = W.t("UI_WORLD_MAP", "Bản đồ thế giới") + " [M]"

	minimap = MinimapClass.new()
	minimap.expand_requested.connect(_toggle_world_map)
	map_col.add_child(minimap)

	# 7. Bottom-Center Dock: Contextual Row + Equipment | 10-Slot Hotbar + Bag | Abilities
	var dock_anchor := VBoxContainer.new()
	dock_anchor.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	dock_anchor.grow_horizontal = Control.GROW_DIRECTION_BOTH
	dock_anchor.grow_vertical = Control.GROW_DIRECTION_BEGIN
	dock_anchor.offset_left = -430
	dock_anchor.offset_right = 430
	dock_anchor.offset_top = -170
	dock_anchor.offset_bottom = -10
	dock_anchor.alignment = BoxContainer.ALIGNMENT_END
	dock_anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dock_anchor.add_theme_constant_override("separation", 6)
	game.add_child(dock_anchor)

	# Interact Hint Pill
	var hint_center := CenterContainer.new()
	hint_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dock_anchor.add_child(hint_center)
	interact_pill = PanelContainer.new()
	interact_pill.theme_type_variation = &"PanelPill"
	interact_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	interact_pill.visible = false
	hint_center.add_child(interact_pill)
	interact_hint = Label.new()
	interact_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	interact_hint.add_theme_font_size_override("font_size", 13)
	interact_hint.add_theme_color_override("font_color", UITheme.TEXT_ACCENT)
	interact_pill.add_child(interact_hint)

	# Expandable Bag Popover (slots 10..29)
	var bag_center := CenterContainer.new()
	bag_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dock_anchor.add_child(bag_center)
	bag_panel = PanelContainer.new()
	bag_panel.theme_type_variation = &"PanelPrimary"
	bag_panel.visible = false
	bag_center.add_child(bag_panel)
	var bag_vbox := VBoxContainer.new()
	bag_vbox.add_theme_constant_override("separation", 6)
	bag_panel.add_child(bag_vbox)
	var bag_head := HBoxContainer.new()
	bag_vbox.add_child(bag_head)
	var bag_title := W.label(bag_head, "UI_BAG_TITLE", "Túi Trữ Vật (11–30)")
	bag_title.theme_type_variation = &"LabelMuted"
	bag_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bag_close := W.button(bag_head, "", func(): bag_panel.hide(), "ButtonSubtle", "✕")
	bag_close.focus_mode = Control.FOCUS_NONE
	bag_grid = GridContainer.new()
	bag_grid.columns = 10
	bag_grid.add_theme_constant_override("h_separation", 4)
	bag_grid.add_theme_constant_override("v_separation", 4)
	bag_vbox.add_child(bag_grid)

	# Contextual & Character Meter Row
	var ctx_center := CenterContainer.new()
	ctx_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dock_anchor.add_child(ctx_center)
	var ctx_row := HBoxContainer.new()
	ctx_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ctx_row.add_theme_constant_override("separation", 8)
	ctx_center.add_child(ctx_row)

	meter_pill = PanelContainer.new()
	meter_pill.theme_type_variation = &"PanelPill"
	meter_pill.visible = false
	ctx_row.add_child(meter_pill)
	meter_lbl = Label.new()
	meter_lbl.add_theme_font_size_override("font_size", 12)
	meter_lbl.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)
	meter_pill.add_child(meter_lbl)

	temper_btn = W.button(ctx_row, "UI_TEMPER", func(): _action("temper", {"slot": selected_slot}), "ButtonSubtle")
	temper_btn.focus_mode = Control.FOCUS_NONE
	temper_btn.visible = false
	plant_btn = W.button(ctx_row, "UI_PLANT", func(): _action("plant", {"slot": selected_slot}), "ButtonSubtle")
	plant_btn.focus_mode = Control.FOCUS_NONE
	plant_btn.visible = false

	# Main Bottom Bar Panel
	var dock_center := CenterContainer.new()
	dock_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dock_anchor.add_child(dock_center)
	var dock_panel := PanelContainer.new()
	dock_panel.theme_type_variation = &"PanelPrimary"
	dock_center.add_child(dock_panel)

	var dock_row := HBoxContainer.new()
	dock_row.add_theme_constant_override("separation", 8)
	dock_panel.add_child(dock_row)

	equipment = HBoxContainer.new()
	equipment.add_theme_constant_override("separation", 4)
	dock_row.add_child(equipment)

	var vsep1 := ColorRect.new()
	vsep1.custom_minimum_size = Vector2(1, 40)
	vsep1.color = UITheme.BORDER_GOLD_DIM
	dock_row.add_child(vsep1)

	inventory = GridContainer.new()
	inventory.columns = 10
	inventory.add_theme_constant_override("h_separation", 4)
	dock_row.add_child(inventory)

	bag_btn = W.button(dock_row, "", func(): bag_panel.visible = not bag_panel.visible, "ButtonIcon", "Túi\n[I]")
	bag_btn.custom_minimum_size = Vector2(48, 48)
	bag_btn.focus_mode = Control.FOCUS_NONE
	bag_btn.add_theme_font_size_override("font_size", 11)
	bag_btn.tooltip_text = W.t("UI_BAG_TOGGLE", "Mở rộng túi đồ [I]")

	var vsep2 := ColorRect.new()
	vsep2.custom_minimum_size = Vector2(1, 40)
	vsep2.color = UITheme.BORDER_GOLD_DIM
	dock_row.add_child(vsep2)

	abilities_hud = preload("res://ui/hud/hud_abilities.gd").new()
	abilities_hud.action.connect(_action)
	dock_row.add_child(abilities_hud)

	# 8. Tutorial Overlay & Controls Help Popover
	tutorial_overlay = preload("res://ui/hud/tutorial_overlay.gd").new()
	game.add_child(tutorial_overlay)

	var help_btn := W.button(game, "", func(): controls_popover.visible = not controls_popover.visible, "ButtonSubtle", "?")
	help_btn.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	help_btn.offset_left = -250
	help_btn.offset_right = -222
	help_btn.offset_top = -42
	help_btn.offset_bottom = -14
	help_btn.focus_mode = Control.FOCUS_NONE
	help_btn.tooltip_text = W.t("UI_HELP_CONTROLS", "Phím tắt")

	controls_popover = PanelContainer.new()
	controls_popover.theme_type_variation = &"PanelPrimary"
	controls_popover.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	controls_popover.offset_left = -520
	controls_popover.offset_right = -222
	controls_popover.offset_top = -150
	controls_popover.offset_bottom = -48
	controls_popover.visible = false
	game.add_child(controls_popover)
	var help_lbl := W.label(controls_popover, "UI_CONTROLS")
	help_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help_lbl.add_theme_font_size_override("font_size", 12)


func _build_modals() -> void:
	modal_stack = ModalStack.new()
	root.add_child(modal_stack)

	trade_panel = preload("res://ui/hud/trade_panel.gd").new()
	trade_panel.action.connect(_action)
	trade_panel.close_requested.connect(func(): modal_stack.close_modal(trade_panel))
	modal_stack.register_modal(trade_panel, true)

	request_panel = preload("res://ui/hud/request_panel.gd").new()
	request_panel.action.connect(_action)
	request_panel.close_requested.connect(func(): modal_stack.close_modal(request_panel))
	modal_stack.register_modal(request_panel, true)

	awakening_panel = preload("res://ui/hud/awakening_panel.gd").new()
	awakening_panel.action.connect(_action)
	awakening_panel.close_requested.connect(func(): modal_stack.close_modal(awakening_panel))
	modal_stack.register_modal(awakening_panel, true)

	pause_menu = PauseMenu.new()
	pause_menu.resume_requested.connect(func(): modal_stack.close_modal(pause_menu))
	pause_menu.save_requested.connect(func():
		save_requested.emit()
		modal_stack.close_modal(pause_menu)
		toast.show_message(W.t("UI_SAVED", "Đã lưu thế giới."), "success")
	)
	pause_menu.settings_requested.connect(func():
		modal_stack.close_modal(pause_menu)
		settings_panel.open_settings()
		modal_stack.open_modal(settings_panel, true)
	)
	pause_menu.tutorial_requested.connect(func():
		modal_stack.close_modal(pause_menu)
		if tutorial_overlay:
			tutorial_overlay.reopen()
	)
	pause_menu.leave_requested.connect(func():
		modal_stack.close_all_dismissible()
		leave_requested.emit()
	)
	modal_stack.register_modal(pause_menu, true)

	settings_panel = preload("res://ui/menu/settings_panel.gd").new()
	settings_panel.close_requested.connect(func(): modal_stack.close_modal(settings_panel))
	modal_stack.register_modal(settings_panel, true)

	_build_world_map_modal()

	char_select = preload("res://ui/menu/character_select.gd").new()
	char_select.character_chosen.connect(func(cid):
		_action("choose_character", {"character": cid})
		modal_stack.close_modal(char_select)
	)
	modal_stack.register_modal(char_select, false)


func _build_world_map_modal() -> void:
	world_map_modal = PanelContainer.new()
	world_map_modal.theme_type_variation = &"PanelModal"
	world_map_modal.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	world_map_modal.custom_minimum_size = Vector2(640, 470)
	world_map_modal.offset_left = -320
	world_map_modal.offset_right = 320
	world_map_modal.offset_top = -235
	world_map_modal.offset_bottom = 235

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	world_map_modal.add_child(vbox)

	var head := HBoxContainer.new()
	vbox.add_child(head)
	var title := W.label(head, "UI_WORLD_MAP", "Bản Đồ Hoang Giới")
	title.theme_type_variation = &"LabelTitle"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var close_btn := W.button(head, "", func(): modal_stack.close_modal(world_map_modal), "ButtonSubtle", "✕")
	close_btn.custom_minimum_size = Vector2(30, 30)

	world_map_view = MinimapClass.new()
	world_map_view.show_labels = true
	world_map_view.custom_minimum_size = Vector2(600, 370)
	world_map_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(world_map_view)

	var legend := Label.new()
	legend.text = "● Vàng: Bạn   ● Xanh lá: Đồng đội   ● Ngọc: Dịch Chuyển Trận (Hoạt động)   ● Xám: Chưa kích hoạt"
	legend.add_theme_font_size_override("font_size", 12)
	legend.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
	vbox.add_child(legend)

	modal_stack.register_modal(world_map_modal, true)


func show_menu(message: String = "") -> void:
	if not menu:
		return
	modal_stack.close_all_dismissible()
	if char_select and modal_stack.is_open(char_select):
		modal_stack.close_modal(char_select)
	menu_backdrop.show()
	menu.show()
	menu_content.refresh_worlds()
	game.hide()
	set_status(message)
	var tree := get_tree()
	if tree != null and tree.root != null:
		var am := tree.root.get_node_or_null("AudioManager")
		if am != null:
			am.stop_ambient()
			am.play_music("menu_theme", 1.2)


func show_game() -> void:
	menu_backdrop.hide()
	menu.hide()
	game.show()
	last_signature = ""


func set_status(message: String) -> void:
	if message.is_empty():
		return
	var translated := tr(message)
	var kind := "error" if ("FAIL" in message or "ERROR" in message or "Không thể" in translated) else "info"
	if toast:
		toast.show_message(translated, kind)


func set_interact_hint(text: String) -> void:
	if not interact_pill or not interact_hint:
		return
	interact_hint.text = text
	interact_pill.visible = not text.is_empty()


func set_target(entity: Dictionary) -> void:
	if entity == current_target:
		return
	current_target = entity.duplicate(true)


func update_state(state: Dictionary, peer_id: int) -> void:
	latest_state = state
	local_id = peer_id
	var player: Dictionary = state.get("players", {}).get(str(peer_id), {})
	if player.is_empty():
		return

	var new_biome := str(player.get("biome", ""))
	if not new_biome.is_empty() and new_biome != current_biome:
		current_biome = new_biome
		biome_banner.text = tr("BIOME_" + new_biome.to_upper())
		biome_banner_panel.modulate.a = 1.0
		banner_timer = 3.0

	var values: Dictionary = player.get("stats", {})
	var clock: Dictionary = state.get("clock", {})
	var duration := maxf(1.0, float(state.get("options", {}).get("day_length", clock.get("day_length", 480))))
	var progress := fmod(float(clock.get("elapsed", 0)), duration) / duration
	var phase := str(clock.get("phase", "day"))
	var season := str(clock.get("season", "autumn"))
	var weather_kind := str(state.get("weather", {}).get("kind", "clear"))

	radial.values = values
	radial.progress = progress
	radial.day_segments = int(clock.get("day_segments", 8))
	radial.dusk_segments = int(clock.get("dusk_segments", 6))
	radial.day_num = int(clock.get("day", 1))
	radial.phase_text = tr("PHASE_" + phase.to_upper())
	radial.season_text = tr("SEASON_" + season.to_upper())
	radial.weather_kind = weather_kind
	radial.weather_text = tr("WEATHER_" + weather_kind.to_upper())
	radial.temperature = int(values.get("temperature", 50))
	radial.biome_text = tr("BIOME_" + new_biome.to_upper()) if not new_biome.is_empty() else ""
	radial.season_warn_text = (tr("UI_SEASON_WARN") % int(clock.get("days_to_next_season", 1))) if bool(clock.get("season_warning", false)) else ""
	radial.is_ghost = bool(player.get("ghost", false))
	radial.is_frenzy = float(values.get("stamina", 100)) < 20.0 or float(values.get("dao", 100)) < 20.0
	radial.tooltip_text = tr("UI_STATS") % [int(values.get("health", 0)), int(values.get("stamina", 0)), int(values.get("dao", 0)), int(clock.get("day", 1)), tr("PHASE_" + phase.to_upper())]
	radial.queue_redraw()

	if minimap:
		minimap.update_map(state, peer_id)
	if minimap_biome_lbl:
		minimap_biome_lbl.text = radial.biome_text
	if world_map_view and world_map_modal.visible:
		world_map_view.update_map(state, peer_id)
	if karma_hud:
		karma_hud.update_karma(state.get("karma", {}))
	if awakening_dot:
		awakening_dot.visible = int(player.get("skill_points", 0)) > 0

	if abilities_hud:
		abilities_hud.refresh(state, player, selected_slot)
		var mtxt: String = abilities_hud.indicator_text
		meter_pill.visible = not mtxt.is_empty()
		meter_lbl.text = mtxt

	if awakening_panel and awakening_panel.visible:
		awakening_panel.refresh(state, player, selected_slot)
	if boss_hud:
		boss_hud.refresh(state, player)

	if char_select:
		var is_probe := "--probe" in OS.get_cmdline_user_args()
		var need_char := str(player.get("character", "")).is_empty() and not is_probe
		if need_char and not modal_stack.is_open(char_select):
			modal_stack.open_modal(char_select, false)
		elif not need_char and modal_stack.is_open(char_select):
			modal_stack.close_modal(char_select)

	var signature := _ui_signature(state, player)
	if signature == last_signature:
		return
	last_signature = signature
	_rebuild_inventory_and_equipment(player)
	_update_contextual_buttons(player)
	recipes.refresh(state, player)


func _rebuild_inventory_and_equipment(player: Dictionary) -> void:
	W.clear(inventory)
	W.clear(bag_grid)
	var slots: Array = player.get("inventory", {}).get("slots", [])
	var occupied := 0
	for i in InventoryComponent.SLOT_COUNT:
		var slot_data: Dictionary = slots[i] if i < slots.size() else {}
		if not slot_data.is_empty():
			occupied += 1
		var button = Slot.new()
		button.configure(i, slot_data)
		button.is_selected = (i == selected_slot)
		button.action.connect(_action)
		button.selected.connect(_select)
		if i < 10:
			inventory.add_child(button)
		else:
			bag_grid.add_child(button)
	if bag_btn:
		bag_btn.text = "%d/%d\n[I]" % [occupied, InventoryComponent.SLOT_COUNT]

	W.clear(equipment)
	for slot_name in ["hand", "body", "head"]:
		var value = player.get("inventory", {}).get("equipment", {}).get(slot_name, {})
		var id := String(value.get("id", "")) if value is Dictionary else String(value)
		var b := Button.new()
		b.theme_type_variation = &"ButtonIcon"
		b.custom_minimum_size = Vector2(44, 48)
		b.focus_mode = Control.FOCUS_NONE
		b.tooltip_text = tr("UI_" + slot_name.to_upper()) + ": " + W.item_name(id)
		var equipped_item = ItemDB.get_item(id)
		b.icon = equipped_item.icon if equipped_item else load("res://assets/ui/icons/ui-%s.svg" % slot_name)
		b.expand_icon = true
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.add_theme_constant_override("icon_max_width", 28)
		var sn: String = str(slot_name)
		b.pressed.connect(func(): _action("unequip", {"slot": sn}))
		equipment.add_child(b)


func _update_contextual_buttons(player: Dictionary) -> void:
	var slots: Array = player.get("inventory", {}).get("slots", [])
	var stack: Dictionary = slots[selected_slot] if selected_slot < slots.size() else {}
	var id := String(stack.get("id", ""))
	var item = ItemDB.get_item(id) if not id.is_empty() else null
	if temper_btn:
		temper_btn.visible = item != null and item.category in [ItemDef.Category.WEAPON, ItemDef.Category.TOOL]
	if plant_btn:
		plant_btn.visible = item != null and ("seed" in id or id == "spirit_rice_seed")


func _ui_signature(state: Dictionary, player: Dictionary) -> String:
	var raw_inv: Dictionary = player.get("inventory", {})
	var clean_slots: Array = []
	for slot in raw_inv.get("slots", []):
		if slot is Dictionary and not slot.is_empty():
			var copy: Dictionary = slot.duplicate()
			copy.erase("_f")
			copy.erase("soak")
			clean_slots.append(copy)
		else:
			clean_slots.append({})
	var clean_equip: Dictionary = {}
	var raw_equip: Dictionary = raw_inv.get("equipment", {})
	for key in raw_equip:
		var item_slot = raw_equip[key]
		if item_slot is Dictionary and not item_slot.is_empty():
			var copy: Dictionary = item_slot.duplicate()
			copy.erase("_f")
			copy.erase("soak")
			clean_equip[key] = copy
		else:
			clean_equip[key] = {}
	var clean_inv := {"slots": clean_slots, "equipment": clean_equip}
	return str(clean_inv) + str(player.get("character", "")) + str(state.get("discovered", [])) + str(state.get("forbidden_recipes", [])) + str(recipes.nearby_tier(state, player)) + str(recipes.nearby_stations(state, player))


func _process(delta: float) -> void:
	if banner_timer > 0.0:
		banner_timer = maxf(0.0, banner_timer - delta)
		biome_banner_panel.modulate.a = clampf(banner_timer, 0.0, 1.0)


func _select(slot: int) -> void:
	selected_slot = slot
	for button in inventory.get_children():
		if "index" in button:
			button.is_selected = (button.index == slot)
	for button in bag_grid.get_children():
		if "index" in button:
			button.is_selected = (button.index == slot)
	var player: Dictionary = latest_state.get("players", {}).get(str(local_id), {})
	_update_contextual_buttons(player)


func _action(verb: String, args: Dictionary) -> void:
	action_requested.emit(verb, args)


func _open_craft_panel() -> void:
	var was_hidden := not craft_frame.visible
	craft_frame.show()
	recipes.refresh(latest_state, latest_state.get("players", {}).get(str(local_id), {}))
	_update_rail_highlight()
	if was_hidden:
		craft_frame.modulate.a = 0.0
		var tw := craft_frame.create_tween()
		tw.tween_property(craft_frame, "modulate:a", 1.0, 0.14)


func _close_craft() -> void:
	craft_frame.hide()
	_update_rail_highlight()


func _update_rail_highlight() -> void:
	for i in rail_buttons.size():
		var active: bool = craft_frame.visible and not recipes.wiki and recipes.group == i
		rail_buttons[i].theme_type_variation = &"ButtonPrimary" if active else &"ButtonIcon"
	if book_button:
		var book_active: bool = craft_frame.visible and recipes.wiki
		book_button.theme_type_variation = &"ButtonPrimary" if book_active else &"ButtonIcon"


func _toggle_craft(book: bool = false) -> void:
	var should_open: bool = not craft_frame.visible or (book and not recipes.wiki)
	if should_open:
		recipes.wiki = book
		_open_craft_panel()
	else:
		_close_craft()
	var tree := get_tree()
	if tree != null and tree.root != null:
		var am := tree.root.get_node_or_null("AudioManager")
		if am != null:
			am.play_ui("ui_book_open" if book else ("ui_craft_open" if craft_frame.visible else "ui_craft_close"))


func open_crafting() -> void:
	recipes.wiki = false
	_open_craft_panel()
	var tree := get_tree()
	if tree != null and tree.root != null:
		var am := tree.root.get_node_or_null("AudioManager")
		if am != null:
			am.play_ui("ui_craft_open")


func _toggle_awakening() -> void:
	if not awakening_panel:
		return
	if modal_stack.is_open(awakening_panel):
		modal_stack.close_modal(awakening_panel)
	else:
		modal_stack.open_modal(awakening_panel, true)
		awakening_panel.refresh(latest_state, latest_state.get("players", {}).get(str(local_id), {}), selected_slot)


func _toggle_world_map() -> void:
	if not world_map_modal:
		return
	if modal_stack.is_open(world_map_modal):
		modal_stack.close_modal(world_map_modal)
	else:
		world_map_view.update_map(latest_state, local_id)
		modal_stack.open_modal(world_map_modal, true)


func _toggle_pause() -> void:
	if not pause_menu:
		return
	if modal_stack.is_open(pause_menu):
		modal_stack.close_modal(pause_menu)
	else:
		modal_stack.open_modal(pause_menu, true)


func _unhandled_key_input(event: InputEvent) -> void:
	if not game.visible or not event is InputEventKey or not event.pressed or event.echo:
		return
	var focused := get_viewport().gui_get_focus_owner()
	if focused is LineEdit or focused is SpinBox:
		return
	if event.keycode == KEY_ESCAPE:
		if modal_stack.has_open_modal():
			modal_stack.close_top()
			get_viewport().set_input_as_handled()
			return
		if craft_frame.visible or bag_panel.visible or controls_popover.visible:
			_close_craft()
			bag_panel.hide()
			controls_popover.hide()
			get_viewport().set_input_as_handled()
			return
		var main_node := get_parent()
		if main_node != null and "preview_recipe" in main_node and not str(main_node.preview_recipe).is_empty():
			return
		if main_node != null and "controls" in main_node and main_node.controls != null and main_node.controls.plant_slot >= 0:
			return
		_toggle_pause()
		get_viewport().set_input_as_handled()
		return
	if event.keycode == SettingsManager.key_for("craft_menu") or event.keycode == SettingsManager.key_for("codex"):
		_toggle_craft(event.keycode == SettingsManager.key_for("codex"))
		get_viewport().set_input_as_handled()
	elif event.keycode == SettingsManager.key_for("awakening"):
		_toggle_awakening()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_I:
		bag_panel.visible = not bag_panel.visible
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_M:
		_toggle_world_map()
		get_viewport().set_input_as_handled()
	elif event.keycode >= KEY_1 and event.keycode <= KEY_9:
		_select(event.keycode - KEY_1)
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_0:
		_select(9)
		get_viewport().set_input_as_handled()
