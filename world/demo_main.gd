extends Node3D
const Session = preload("res://world/demo_session.gd")
const UI = preload("res://ui/demo/demo_ui.gd")
const View = preload("res://entities/demo/demo_view.gd")
var controls = preload("res://world/demo_controls.gd").new()
var session
var ui
var view
var camera: Camera3D
var state: Dictionary = {}
var zoom := 20.0
var input_timer := 0.0
var preview_recipe := ""
var preview: MeshInstance3D
var predicted := Vector3.ZERO
var colliders: Dictionary = {}

func _ready() -> void:
	TranslationServer.set_locale("vi")
	controls.main = self
	get_tree().auto_accept_quit = false
	session = Session.new()
	session.name = "Session"
	add_child(session)
	view = View.new()
	add_child(view)
	ui = UI.new()
	add_child(ui)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = zoom
	camera.far = 180
	add_child(camera)
	camera.current = true
	preview = MeshInstance3D.new()
	preview.mesh = CylinderMesh.new()
	preview.visible = false
	add_child(preview)
	_ground_collision()
	ui.host_requested.connect(_host)
	ui.join_requested.connect(_join)
	ui.action_requested.connect(_action)
	ui.leave_requested.connect(_leave)
	ui.save_requested.connect(session.save)
	session.state_received.connect(_receive)
	session.action_feedback.connect(func(success): ui.set_status("" if success else "DEMO_ACTION_FAILED"))
	session.ended.connect(func(message): _clear_world(); ui.show_menu(tr(message)))
	ui.show_menu()
	var args := OS.get_cmdline_user_args()
	if "--host" in args:
		_host({"name": "SmokeHost", "seed": 12345, "day_length": 480, "death_mode": "continue"})
	elif "--join" in args:
		_join("127.0.0.1", "SmokeClient" + str(OS.get_process_id()))
	if "--probe" in args:
		var probe = load("res://tests/network_probe.gd").new()
		probe.main = self
		add_child(probe)

func _host(options: Dictionary) -> void:
	var error: Error = session.start(options)
	if error != OK:
		ui.set_status(tr("CONNECTION_FAILED") + " " + error_string(error))
	else:
		ui.show_game()

func _join(address: String, player_name: String) -> void:
	var error := NetworkManager.join(address, player_name)
	if error != OK:
		ui.set_status(tr("CONNECTION_FAILED") + " " + error_string(error))

func _receive(data: Dictionary) -> void:
	var was_empty := state.is_empty()
	state = data
	var id := multiplayer.get_unique_id()
	if not state.get("players", {}).has(str(id)):
		return
	if was_empty:
		ui.show_game()
		var p: Array = state.players[str(id)].position
		predicted = Vector3(p[0], 0, p[2])
	ui.update_state(state, id)
	_obstacles()

func _process(delta: float) -> void:
	if state.is_empty() or not NetworkManager.active:
		return
	var id := multiplayer.get_unique_id()
	var player: Dictionary = state.get("players", {}).get(str(id), {})
	if player.is_empty():
		return
	var direction := Vector2.ZERO
	var focused := get_viewport().gui_get_focus_owner()
	if not focused is LineEdit and not focused is SpinBox:
		direction = Vector2(float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)), float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))).limit_length()
	input_timer += delta
	if input_timer >= 0.05:
		input_timer = 0
		session.move_input(direction)
	var pos: Array = player.position
	var authoritative := Vector3(float(pos[0]), 0, float(pos[2]))
	if multiplayer.is_server():
		predicted = authoritative
	else:
		predicted = predicted.lerp(authoritative, minf(delta * 8, 1))
		predicted += Vector3(direction.x, 0, direction.y) * delta * 5.0
	camera.size = zoom
	camera.position = predicted + Vector3(0, 22, 18)
	camera.look_at(predicted)
	view.local_prediction = predicted
	view.render(state, id)
	if not get_viewport().gui_get_hovered_control():
		ui.set_target(view.get_target(_mouse_world()))
	if not preview_recipe.is_empty() or controls.plant_slot >= 0:
		preview.visible = true
		preview.position = _mouse_world() + Vector3(0, 0.25, 0)
		var valid := preview.position.distance_to(authoritative) <= 5.0 and absf(preview.position.x) <= 40 and absf(preview.position.z) <= 40
		for entity in state.get("structures", []) + state.get("nodes", []):
			var p: Array = entity.position
			var radius := 3.0 if entity.kind == "spring" else 1.5
			valid = valid and Vector2(p[0], p[2]).distance_to(Vector2(preview.position.x, preview.position.z)) >= radius
		var material := StandardMaterial3D.new()
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color = Color(0.2, 1, 0.3, 0.45) if valid else Color(1, 0.1, 0.1, 0.45)
		preview.material_override = material

func _unhandled_input(event: InputEvent) -> void:
	controls.handle(event)

func _action(verb: String, args: Dictionary) -> void:
	controls.action(verb, args)

func _mouse_world() -> Vector3:
	var mouse := get_viewport().get_mouse_position()
	var hit = Plane(Vector3.UP, 0).intersects_ray(camera.project_ray_origin(mouse), camera.project_ray_normal(mouse))
	return hit if hit != null else Vector3.ZERO

func _ground_collision() -> void:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	shape.shape.size = Vector3(80, 1, 80)
	shape.position.y = -0.5
	body.add_child(shape)
	add_child(body)

func _obstacles() -> void:
	var present := {}
	for entity in state.get("nodes", []):
		var key := int(entity.uid)
		present[key] = true
		var solid: bool = str(entity.kind) in ["tree", "bamboo", "rock", "spirit_rock"] and not entity.get("depleted", false)
		if solid and not colliders.has(key):
			var body := StaticBody3D.new()
			var shape := CollisionShape3D.new()
			shape.shape = CylinderShape3D.new()
			shape.shape.radius = 0.4
			shape.shape.height = 2
			body.add_child(shape)
			var p: Array = entity.position
			body.position = Vector3(p[0], 1, p[2])
			add_child(body)
			colliders[key] = body
		elif not solid and colliders.has(key):
			colliders[key].queue_free()
			colliders.erase(key)
	for key in colliders.keys():
		if not present.has(key):
			colliders[key].queue_free()
			colliders.erase(key)

func _clear_world() -> void:
	state.clear()
	controls.cancel()
	for body in colliders.values():
		body.queue_free()
	colliders.clear()
	view.render({}, multiplayer.get_unique_id())

func _leave() -> void:
	session.save()
	session.stop()
	NetworkManager.leave()
	_clear_world()
	ui.show_menu()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		session.save()
		get_tree().quit()

