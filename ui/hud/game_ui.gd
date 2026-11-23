extends CanvasLayer

signal host_requested(options: Dictionary)
signal join_requested(address: String, player_name: String)
signal action_requested(verb: String, args: Dictionary)
signal leave_requested
signal save_requested
const W = preload("res://ui/hud/hud_widgets.gd")
const Slot = preload("res://ui/hud/hud_slot.gd")
var root: Control
var menu: PanelContainer
var menu_backdrop: Control
var game: Control
var status: Label
var stats: Label
var equipment: HBoxContainer
var inventory: GridContainer
var recipes: VBoxContainer
var target_panel: VBoxContainer
var current_target: Dictionary = {}
var selected_slot := 0
var last_signature := ""
var latest_state: Dictionary = {}
var local_id := 1
var radial: Control
var menu_content: VBoxContainer
var target_frame: Control
var craft_frame: Control
var biome_banner: Label
var current_biome := ""
var banner_timer := 0.0
var minimap: Control
var karma_hud: VBoxContainer
var trade_panel: PanelContainer
var request_panel: PanelContainer
var interact_hint: Label
var abilities_hud: HBoxContainer
var char_select: PanelContainer
var awakening_panel: PanelContainer
var boss_hud: PanelContainer
var settings_panel: PanelContainer
var tutorial_overlay: PanelContainer

func _ready() -> void:
	layer = 20
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = W.theme()
	add_child(root)
	menu_backdrop = preload("res://ui/menu/menu_backdrop.gd").new()
	root.add_child(menu_backdrop)
	menu = PanelContainer.new()
	menu.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	menu.position = Vector2(-240, -320)
	menu.custom_minimum_size = Vector2(480, 620)
	root.add_child(menu)
	menu_content = preload("res://ui/menu/main_menu.gd").new()
	menu_content.host_requested.connect(func(options): host_requested.emit(options))
	menu_content.join_requested.connect(func(address, name_value): join_requested.emit(address, name_value))
	menu_content.settings_requested.connect(func(): if settings_panel: settings_panel.open_settings())
	menu.add_child(menu_content)
	game = Control.new()
	game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(game)
	var hud := W.panel(game, Vector2(280, 12), Vector2(540, 65))
	stats = W.label(hud, "UI_STATS")
	stats.custom_minimum_size.x = 510
	stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats.add_theme_font_size_override("font_size", 13)
	radial = preload("res://ui/hud/hud_radial.gd").new()
	game.add_child(radial)
	radial.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	radial.position += Vector2(-236, 13)
	var commands := HBoxContainer.new()
	hud.add_child(commands)
	abilities_hud = preload("res://ui/hud/hud_abilities.gd").new()
	abilities_hud.action.connect(_action)
	commands.add_child(abilities_hud)
	W.button(commands, "UI_AWAKENING_BTN", func(): _toggle_awakening())
	W.button(commands, "UI_SETTINGS", func(): if settings_panel: settings_panel.open_settings())
	W.button(commands, "UI_SAVE", func(): save_requested.emit())
	W.button(commands, "UI_LEAVE", func(): leave_requested.emit())
	var left := W.panel(game, Vector2(84, 110), Vector2(300, 430))
	craft_frame = left.get_parent()
	recipes = preload("res://ui/hud/hud_recipes.gd").new()
	recipes.action.connect(_action)
	left.add_child(recipes)
	craft_frame.hide()
	var rail := W.panel(game, Vector2(10, 110), Vector2(64, 0))
	var category_icons := ["tools", "light", "survival", "combat", "buildings", "talismans", "puppets"]
	for i in 7:
		var keys := ["UI_TOOLS", "UI_LIGHT", "UI_SURVIVAL", "UI_COMBAT", "UI_BUILDINGS", "UI_TALISMANS", "UI_PUPPETS"]
		var category_button := W.button(rail, keys[i], func():
			recipes.group = i
			recipes.wiki = false
			craft_frame.show()
			recipes.refresh(latest_state, latest_state.get("players", {}).get(str(local_id), {})))
		category_button.tooltip_text = tr(keys[i])
		category_button.text = ""
		category_button.icon = load("res://assets/ui/icons/ui-%s.svg" % category_icons[i])
		category_button.expand_icon = true
		category_button.custom_minimum_size = Vector2(44, 44)
		category_button.add_theme_constant_override("icon_max_width", 30)
	var book_button := W.button(rail, "UI_BOOK", func(): _toggle_craft(true))
	book_button.tooltip_text = tr("UI_BOOK") + " [B]"
	book_button.text = ""
	book_button.icon = preload("res://assets/ui/icons/ui-book.svg")
	book_button.expand_icon = true
	book_button.custom_minimum_size = Vector2(44, 44)
	book_button.add_theme_constant_override("icon_max_width", 30)
	W.button(left, "UI_CLOSE", func(): craft_frame.hide())
	var target_box := W.panel(game, Vector2(0, 95), Vector2(270, 0))
	target_frame = target_box.get_parent()
	target_box.get_parent().set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	target_box.get_parent().position += Vector2(-304, 190)
	target_panel = preload("res://ui/hud/hud_target.gd").new()
	target_panel.action.connect(_action)
	var target_scroll := ScrollContainer.new()
	target_scroll.custom_minimum_size = Vector2(270, 230)
	target_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	target_box.add_child(target_scroll)
	target_scroll.add_child(target_panel)
	target_frame.hide()
	var bottom := W.panel(game, Vector2.ZERO, Vector2(0, 0))
	var bottom_panel := bottom.get_parent() as Control
	bottom_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_panel.offset_top = -204
	bottom_panel.offset_bottom = -12
	bottom_panel.offset_left = 80
	bottom_panel.offset_right = -80
	equipment = HBoxContainer.new()
	bottom.add_child(equipment)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 116
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	bottom.add_child(scroll)
	inventory = GridContainer.new()
	inventory.columns = 15
	inventory.add_theme_constant_override("h_separation", 4)
	inventory.add_theme_constant_override("v_separation", 4)
	scroll.add_child(inventory)
	W.label(bottom, "UI_CONTROLS").add_theme_font_size_override("font_size", 12)
	status = W.label(root, "UI_READY")
	status.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	status.offset_top = 82
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	biome_banner = W.label(game, "")
	biome_banner.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	biome_banner.offset_top = 130
	biome_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	biome_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	biome_banner.add_theme_font_size_override("font_size", 42)
	biome_banner.modulate.a = 0.0
	interact_hint = W.label(game, "")
	interact_hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	interact_hint.offset_top = -236
	interact_hint.offset_bottom = -208
	interact_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interact_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	interact_hint.add_theme_font_size_override("font_size", 16)
	interact_hint.visible = false
	var map_box := W.panel(game, Vector2.ZERO, Vector2(180, 120))
	var map_panel := map_box.get_parent() as Control
	map_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	map_panel.offset_left = -204
	map_panel.offset_right = -14
	map_panel.offset_top = -348
	map_panel.offset_bottom = -212
	minimap = preload("res://ui/hud/hud_minimap.gd").new()
	map_box.add_child(minimap)
	var karma_box := W.panel(game, Vector2(10, 12), Vector2(200, 0))
	karma_hud = preload("res://ui/hud/hud_karma.gd").new()
	karma_box.add_child(karma_hud)
	trade_panel = preload("res://ui/hud/trade_panel.gd").new()
	trade_panel.action.connect(_action)
	game.add_child(trade_panel)
	request_panel = preload("res://ui/hud/request_panel.gd").new()
	request_panel.action.connect(_action)
	game.add_child(request_panel)
	target_panel.open_trade.connect(func(npc): trade_panel.open_npc(npc))
	target_panel.open_request.connect(func(npc): request_panel.open_npc(npc))
	char_select = preload("res://ui/menu/character_select.gd").new()
	char_select.character_chosen.connect(func(cid): _action("choose_character", {"character": cid}))
	char_select.hide()
	game.add_child(char_select)
	awakening_panel = preload("res://ui/hud/awakening_panel.gd").new()
	awakening_panel.action.connect(_action)
	game.add_child(awakening_panel)
	boss_hud = preload("res://ui/hud/hud_boss.gd").new()
	game.add_child(boss_hud)
	tutorial_overlay = preload("res://ui/hud/tutorial_overlay.gd").new()
	game.add_child(tutorial_overlay)
	settings_panel = preload("res://ui/menu/settings_panel.gd").new()
	root.add_child(settings_panel)
	show_menu()

func show_menu(message: String = "") -> void:
	if not menu: return
	menu_backdrop.show()
	menu.show()
	menu_content.refresh_worlds()
	game.hide()
	set_status(message)

func show_game() -> void:
	menu_backdrop.hide()
	menu.hide()
	game.show()
	last_signature = ""

func set_status(message: String) -> void:
	if status: status.text = tr(message)

func set_interact_hint(text: String) -> void:
	if not interact_hint: return
	interact_hint.text = text
	interact_hint.visible = not text.is_empty()

func set_target(entity: Dictionary) -> void:
	if entity == current_target: return
	current_target = entity.duplicate(true)
	target_frame.visible = not entity.is_empty()
	target_panel.selected_slot = selected_slot
	target_panel.refresh(current_target)

func update_state(state: Dictionary, peer_id: int) -> void:
	latest_state = state
	local_id = peer_id
	target_panel.teleports = state.get("teleports", [])
	var player: Dictionary = state.get("players", {}).get(str(peer_id), {})
	if player.is_empty(): return
	var new_biome := str(player.get("biome", ""))
	if not new_biome.is_empty() and new_biome != current_biome:
		current_biome = new_biome
		biome_banner.text = tr("BIOME_" + new_biome.to_upper())
		biome_banner.modulate.a = 1.0
		banner_timer = 3.0
	var values: Dictionary = player.get("stats", {})
	var clock: Dictionary = state.get("clock", {})
	var duration := maxf(1, float(state.get("options", {}).get("day_length", clock.get("day_length", 480))))
	var progress := fmod(float(clock.get("elapsed", 0)), duration) / duration
	var phase := str(clock.get("phase", "day"))
	var season := str(clock.get("season", "autumn"))
	var weather_kind := str(state.get("weather", {}).get("kind", "clear"))
	radial.values = values
	radial.progress = progress
	radial.day_segments = int(clock.get("day_segments", 8))
	radial.dusk_segments = int(clock.get("dusk_segments", 6))
	radial.queue_redraw()
	if minimap:
		minimap.update_map(state, peer_id)
	if karma_hud:
		karma_hud.update_karma(state.get("karma", {}))
	if abilities_hud:
		abilities_hud.refresh(state, player, selected_slot)
	if awakening_panel and awakening_panel.visible:
		awakening_panel.refresh(state, player, selected_slot)
	if boss_hud:
		boss_hud.refresh(state, player)
	if char_select:
		var is_probe := "--probe" in OS.get_cmdline_user_args()
		char_select.visible = str(player.get("character", "")).is_empty() and not is_probe
	stats.text = tr("UI_DAY") % [int(clock.get("day", 1)), tr("PHASE_" + phase.to_upper())]
	stats.text += " | " + tr("SEASON_" + season.to_upper())
	if bool(clock.get("season_warning", false)):
		stats.text += " (" + (tr("UI_SEASON_WARN") % int(clock.get("days_to_next_season", 1))) + ")"
	stats.text += " | " + tr("WEATHER_" + weather_kind.to_upper())
	stats.text += " | " + (tr("UI_TEMP") % int(values.get("temperature", 50)))
	if not new_biome.is_empty():
		stats.text += "  |  " + tr("BIOME_" + new_biome.to_upper())
	radial.tooltip_text = tr("UI_STATS") % [int(values.get("health", 0)), int(values.get("stamina", 0)), int(values.get("dao", 0)), int(clock.get("day", 1)), tr("PHASE_" + phase.to_upper())]
	if player.get("ghost", false): stats.text += " | " + tr("UI_GHOST")
	if float(values.get("stamina", 100)) < 20 or float(values.get("dao", 100)) < 20: stats.text += " | " + tr("UI_FRENZY")
	var signature := _ui_signature(state, player)
	if signature == last_signature: return
	last_signature = signature
	W.clear(inventory)
	var slots: Array = player.get("inventory", {}).get("slots", [])
	for i in InventoryComponent.SLOT_COUNT:
		var button = Slot.new()
		button.configure(i, slots[i] if i < slots.size() else {})
		button.is_selected = i == selected_slot
		button.action.connect(_action)
		button.selected.connect(_select)
		inventory.add_child(button)
	W.clear(equipment)
	W.label(equipment, "UI_EQUIPMENT")
	for slot_name in ["hand", "body", "head"]:
		var value = player.get("inventory", {}).get("equipment", {}).get(slot_name, {})
		var id := String(value.get("id", "")) if value is Dictionary else String(value)
		var b := W.button(equipment, "UI_" + slot_name.to_upper(), func(): _action("unequip", {"slot": slot_name}))
		b.tooltip_text = b.text + ": " + W.item_name(id)
		var equipped_item = ItemDB.get_item(id)
		b.icon = equipped_item.icon if equipped_item else load("res://assets/ui/icons/ui-%s.svg" % slot_name)
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", 24)
	W.button(equipment, "UI_TEMPER", func(): _action("temper", {"slot": selected_slot}))
	W.button(equipment, "UI_PLANT", func(): _action("plant", {"slot": selected_slot}))
	recipes.refresh(state, player)

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
		biome_banner.modulate.a = clampf(banner_timer, 0.0, 1.0)


func _select(slot: int) -> void:
	selected_slot = slot
	for button in inventory.get_children():
		button.is_selected = button.index == slot
	target_panel.selected_slot = slot
	target_panel.refresh(current_target)

func _action(verb: String, args: Dictionary) -> void:
	print("[GameUI] action ", verb, " ", args)
	action_requested.emit(verb, args)

func _toggle_craft(book: bool = false) -> void:
	craft_frame.visible = not craft_frame.visible or book
	recipes.wiki = book
	recipes.refresh(latest_state, latest_state.get("players", {}).get(str(local_id), {}))

func open_crafting() -> void:
	craft_frame.show()
	recipes.wiki = false
	recipes.refresh(latest_state, latest_state.get("players", {}).get(str(local_id), {}))

func _toggle_awakening() -> void:
	if not awakening_panel: return
	awakening_panel.visible = not awakening_panel.visible
	if awakening_panel.visible:
		awakening_panel.refresh(latest_state, latest_state.get("players", {}).get(str(local_id), {}), selected_slot)

func _unhandled_key_input(event: InputEvent) -> void:
	if not game.visible or not event is InputEventKey or not event.pressed or event.echo: return
	if event.keycode == SettingsManager.key_for("craft_menu") or event.keycode == SettingsManager.key_for("codex"):
		_toggle_craft(event.keycode == SettingsManager.key_for("codex"))
		get_viewport().set_input_as_handled()
	elif event.keycode == SettingsManager.key_for("awakening"):
		_toggle_awakening()
		get_viewport().set_input_as_handled()
