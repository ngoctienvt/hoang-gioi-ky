extends Control
## Manages modal dialogs with a shared dark translucent dimmer, ESC handling, and smooth open/close tweens.

var dimmer: ColorRect
var _stack: Array[Dictionary] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	dimmer = ColorRect.new()
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.015, 0.025, 0.024, 0.64)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	dimmer.visible = false
	dimmer.modulate.a = 0.0
	dimmer.gui_input.connect(_on_dimmer_input)
	add_child(dimmer)


func register_modal(node: Control, dismissible: bool = true) -> void:
	if node.get_parent() != self:
		if node.get_parent() != null:
			node.get_parent().remove_child(node)
		add_child(node)
	node.visible = false
	node.set_meta("_modal_dismissible", dismissible)


func open_modal(node: Control, dismissible: bool = true) -> void:
	if node == null:
		return
	register_modal(node, dismissible)
	# Remove existing entry if already in stack
	for i in range(_stack.size() - 1, -1, -1):
		if _stack[i].node == node:
			_stack.remove_at(i)
	_stack.append({"node": node, "dismissible": dismissible})
	move_child(dimmer, get_child_count() - 2 if get_child_count() >= 2 else 0)
	move_child(node, get_child_count() - 1)
	_show_dimmer()
	node.visible = true
	node.modulate.a = 0.0
	node.scale = Vector2(0.96, 0.96)
	node.pivot_offset = node.size * 0.5
	var tw := node.create_tween().set_parallel(true)
	tw.tween_property(node, "modulate:a", 1.0, 0.14).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_focus_first(node)


func close_modal(node: Control) -> void:
	if node == null:
		return
	for i in range(_stack.size() - 1, -1, -1):
		if _stack[i].node == node:
			_stack.remove_at(i)
	if node.visible:
		var tw := node.create_tween()
		tw.tween_property(node, "modulate:a", 0.0, 0.10).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tw.tween_callback(func():
			if is_instance_valid(node) and not is_open(node):
				node.visible = false
				node.scale = Vector2.ONE
		)
	if _stack.is_empty():
		_hide_dimmer()
	else:
		var top: Control = _stack[-1].node
		move_child(dimmer, maxi(0, get_child_count() - 2))
		move_child(top, get_child_count() - 1)


func close_top() -> bool:
	if _stack.is_empty():
		return false
	var top: Dictionary = _stack[-1]
	if not bool(top.get("dismissible", true)):
		return false
	close_modal(top.node)
	return true


func close_all_dismissible() -> void:
	for i in range(_stack.size() - 1, -1, -1):
		if bool(_stack[i].get("dismissible", true)):
			close_modal(_stack[i].node)


func is_open(node: Control) -> bool:
	for entry in _stack:
		if entry.node == node:
			return true
	return false


func has_open_modal() -> bool:
	return not _stack.is_empty()


func _show_dimmer() -> void:
	if dimmer.visible and dimmer.modulate.a >= 0.99:
		return
	dimmer.visible = true
	var tw := dimmer.create_tween()
	tw.tween_property(dimmer, "modulate:a", 1.0, 0.14)


func _hide_dimmer() -> void:
	if not dimmer.visible:
		return
	var tw := dimmer.create_tween()
	tw.tween_property(dimmer, "modulate:a", 0.0, 0.12)
	tw.tween_callback(func():
		if _stack.is_empty() and is_instance_valid(dimmer):
			dimmer.visible = false
	)


func _on_dimmer_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close_top()
		accept_event()


func _focus_first(node: Control) -> void:
	for child in node.find_children("*", "Button", true, false):
		var btn := child as Button
		if btn != null and btn.visible and not btn.disabled and btn.focus_mode != Control.FOCUS_NONE:
			btn.grab_focus()
			return
