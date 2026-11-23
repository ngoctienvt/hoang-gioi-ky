extends CanvasLayer

signal host_requested(options: Dictionary)
signal join_requested(address: String, player_name: String)
signal action_requested(verb: String, args: Dictionary)
signal leave_requested
signal save_requested
const W = preload("res://ui/demo/demo_widgets.gd")
const Slot = preload("res://ui/demo/demo_slot.gd")
var root: Control
var menu: PanelContainer
var game: Control
var status: Label
var stats: Label
var equipment: HBoxContainer
var inventory: HBoxContainer
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

func _ready() -> void:
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = W.theme()
	add_child(root)
	menu = PanelContainer.new()
	menu.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	menu.position = Vector2(-240, -320)
	menu.custom_minimum_size = Vector2(480, 620)
	root.add_child(menu)
	menu_content = preload("res://ui/demo/demo_menu.gd").new()
	menu_content.host_requested.connect(func(options): host_requested.emit(options))
	menu_content.join_requested.connect(func(address, name_value): join_requested.emit(address, name_value))
	menu.add_child(menu_content)
	game = Control.new()
	game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(game)
	var hud := W.panel(game, Vector2(280, 12), Vector2(540, 65))
	stats = W.label(hud, "DEMO_STATS")
	radial = preload("res://ui/demo/demo_radial.gd").new()
	game.add_child(radial)
	radial.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	radial.position += Vector2(-295, 13)
	var commands := HBoxContainer.new()
	hud.add_child(commands)
	W.button(commands, "DEMO_BEAST", func(): _action("ability", {"name": "beast"}))
	W.button(commands, "DEMO_SENSE", func(): _action("ability", {"name": "sense"}))
	W.button(commands, "DEMO_SAVE", func(): save_requested.emit())
	W.button(commands, "DEMO_LEAVE", func(): leave_requested.emit())
	var left := W.panel(game, Vector2(115, 100), Vector2(260, 430))
	craft_frame = left.get_parent()
	recipes = preload("res://ui/demo/demo_recipes.gd").new()
	recipes.action.connect(_action)
	left.add_child(recipes)
	craft_frame.hide()
	var rail := W.panel(game, Vector2(10, 100), Vector2(95, 0))
	for i in 5:
		var keys := ["DEMO_TOOLS", "DEMO_LIGHT", "DEMO_SURVIVAL", "DEMO_COMBAT", "DEMO_BUILDINGS"]
		W.button(rail, keys[i], func():
			recipes.group = i
			recipes.wiki = false
			craft_frame.show()
			recipes.refresh(latest_state, latest_state.get("players", {}).get(str(local_id), {})))
	W.button(rail, "DEMO_BOOK", func(): _toggle_craft(true))
	W.button(left, "DEMO_CLOSE", func(): craft_frame.hide())
	var target_box := W.panel(game, Vector2(0, 95), Vector2(270, 0))
	target_frame = target_box.get_parent()
	target_box.get_parent().set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	target_box.get_parent().position += Vector2(-285, 95)
	target_panel = preload("res://ui/demo/demo_target.gd").new()
	target_panel.action.connect(_action)
	var target_scroll := ScrollContainer.new()
	target_scroll.custom_minimum_size = Vector2(270, 360)
	target_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	target_box.add_child(target_scroll)
	target_scroll.add_child(target_panel)
	target_frame.hide()
	var bottom := W.panel(game, Vector2.ZERO, Vector2(0, 0))
	var bottom_panel := bottom.get_parent() as Control
	bottom_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_panel.offset_top = -155
	bottom_panel.offset_left = 80
	bottom_panel.offset_right = -80
	equipment = HBoxContainer.new()
	bottom.add_child(equipment)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 85
	bottom.add_child(scroll)
	inventory = HBoxContainer.new()
	scroll.add_child(inventory)
	W.label(bottom, "DEMO_CONTROLS").add_theme_font_size_override("font_size", 12)
	status = W.label(root, "DEMO_READY")
	status.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	status.offset_top = 82
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	show_menu()

func show_menu(message: String = "") -> void:
	if not menu: return
	menu.show()
	menu_content.refresh_worlds()
	game.hide()
	set_status(message)

func show_game() -> void:
	menu.hide()
	game.show()
	last_signature = ""

func set_status(message: String) -> void:
	if status: status.text = tr(message)

func set_target(entity: Dictionary) -> void:
	if entity == current_target: return
	current_target = entity.duplicate(true)
	target_frame.visible = not entity.is_empty()
	target_panel.selected_slot = selected_slot
	target_panel.refresh(current_target)

func update_state(state: Dictionary, peer_id: int) -> void:
	latest_state = state
	local_id = peer_id
	var player: Dictionary = state.get("players", {}).get(str(peer_id), {})
	if player.is_empty(): return
	var values: Dictionary = player.get("stats", {})
	var clock: Dictionary = state.get("clock", {})
	var duration := maxf(1, float(state.get("options", {}).get("day_length", clock.get("day_length", 480))))
	var progress := fmod(float(clock.get("elapsed", 0)), duration) / duration
	var phase := "day" if progress < 0.5 else "dusk" if progress < 0.875 else "night"
	radial.values = values
	radial.progress = progress
	radial.queue_redraw()
	stats.text = tr("DEMO_DAY") % [int(clock.get("day", 1)), tr("PHASE_" + phase.to_upper())]
	radial.tooltip_text = tr("DEMO_STATS") % [int(values.get("health", 0)), int(values.get("stamina", 0)), int(values.get("dao", 0)), int(clock.get("day", 1)), tr("PHASE_" + phase.to_upper())]
	if player.get("ghost", false): stats.text += " | " + tr("DEMO_GHOST")
	if float(values.get("stamina", 100)) < 20 or float(values.get("dao", 100)) < 20: stats.text += " | " + tr("DEMO_FRENZY")
	var signature := str(player.get("inventory", {})) + str(state.get("discovered", [])) + str(recipes.nearby_tier(state, player))
	if signature == last_signature: return
	last_signature = signature
	W.clear(inventory)
	var slots: Array = player.get("inventory", {}).get("slots", [])
	for i in 15:
		var button = Slot.new()
		button.configure(i, slots[i] if i < slots.size() else {})
		button.action.connect(_action)
		button.selected.connect(_select)
		inventory.add_child(button)
	W.clear(equipment)
	W.label(equipment, "DEMO_EQUIPMENT")
	for slot_name in ["hand", "body", "head"]:
		var value = player.get("inventory", {}).get("equipment", {}).get(slot_name, {})
		var id := String(value.get("id", "")) if value is Dictionary else String(value)
		var b := W.button(equipment, "DEMO_" + slot_name.to_upper(), func(): _action("unequip", {"slot": slot_name}))
		b.text += ": " + W.item_name(id)
	W.button(equipment, "DEMO_TEMPER", func(): _action("temper", {"slot": selected_slot}))
	W.button(equipment, "DEMO_PLANT", func(): _action("plant", {"slot": selected_slot}))
	recipes.refresh(state, player)

func _select(slot: int) -> void:
	selected_slot = slot
	target_panel.selected_slot = slot
	target_panel.refresh(current_target)

func _action(verb: String, args: Dictionary) -> void:
	print("[DemoUI] action ", verb, " ", args)
	action_requested.emit(verb, args)

func _toggle_craft(book: bool = false) -> void:
	craft_frame.visible = not craft_frame.visible or book
	recipes.wiki = book
	recipes.refresh(latest_state, latest_state.get("players", {}).get(str(local_id), {}))

func open_crafting() -> void:
	craft_frame.show()
	recipes.wiki = false
	recipes.refresh(latest_state, latest_state.get("players", {}).get(str(local_id), {}))

func _unhandled_key_input(event: InputEvent) -> void:
	if not game.visible or not event is InputEventKey or not event.pressed or event.echo: return
	if event.keycode == KEY_TAB or event.keycode == KEY_B:
		_toggle_craft(event.keycode == KEY_B)
		get_viewport().set_input_as_handled()
