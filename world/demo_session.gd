extends Node
## Authenticated intent boundary; clients never supply their identity or world state.
signal state_received(state: Dictionary)
signal ended(message: String)
signal action_feedback(success: bool)
const World = preload("res://world/simulation/demo_world.gd")
const Avatar = preload("res://entities/demo/network_avatar.gd")
var world
var state: Dictionary = {}
var avatars: Node3D
var spawner: MultiplayerSpawner
var elapsed := 0.0
var last_day := 1
var limits: Dictionary = {}
var sent_sections: Dictionary = {}

func _ready() -> void:
	avatars = Node3D.new()
	avatars.name = "Avatars"
	add_child(avatars)
	spawner = MultiplayerSpawner.new()
	spawner.name = "Spawner"
	spawner.spawn_path = ^"../Avatars"
	spawner.spawn_function = _spawn_avatar
	add_child(spawner)
	NetworkManager.joined.connect(func(): request_register.rpc_id(1, NetworkManager.player_name))
	NetworkManager.disconnected.connect(func(message): stop(); ended.emit(message))
	multiplayer.peer_disconnected.connect(_peer_left)

func start(options: Dictionary) -> Error:
	var error := NetworkManager.host(str(options.get("name", "")))
	if error != OK:
		return error
	world = World.new()
	var saved := SaveManager.load_world(str(options.get("load_slot", ""))) if not str(options.get("load_slot", "")).is_empty() else {}
	if not str(options.get("load_slot", "")).is_empty() and saved.is_empty():
		NetworkManager.leave()
		world = null
		return ERR_FILE_CORRUPT
	if saved.is_empty():
		world.initialize(int(options.get("seed", 12345)), options)
	else:
		world.restore(saved)
	world.add_player(1, NetworkManager.player_name)
	spawner.spawn({"peer_id": 1, "position": world.state.players["1"].position})
	sent_sections.clear()
	_publish()
	return OK
func stop() -> void:
	world = null
	state.clear()
	sent_sections.clear()
	for avatar in avatars.get_children():
		avatar.queue_free()
	limits.clear()
func save() -> void:
	if world != null and multiplayer.is_server():
		var error := SaveManager.save_world(world.snapshot(), "world_" + str(world.state.seed))
		print("[save] result=", error)
func _spawn_avatar(data: Dictionary) -> Node:
	var avatar := Avatar.new()
	avatar.name = str(data.peer_id)
	avatar.peer_id = int(data.peer_id)
	avatar.position = Vector3(data.position[0], 0, data.position[2])
	avatar.authoritative_position = avatar.position
	return avatar
@rpc("any_peer", "reliable")
func request_register(display_name: String) -> void:
	if world == null or not multiplayer.is_server():
		return
	var sender := multiplayer.get_remote_sender_id()
	if sender <= 1 or world.state.players.has(str(sender)):
		return
	var cleaned := NetworkManager.clean_name(display_name)
	for player in world.state.players.values():
		if player.name == cleaned:
			registration_failed.rpc_id(sender, "NAME_IN_USE")
			return
	world.add_player(sender, cleaned)
	spawner.spawn({"peer_id": sender, "position": world.state.players[str(sender)].position})
	receive_state.rpc_id(sender, world.snapshot(), true)
	print("[network] registered ", sender)

@rpc("authority", "reliable")
func registration_failed(message: String) -> void:
	NetworkManager.leave()
	stop()
	ended.emit(message)

func intent(verb: String, args: Dictionary) -> void:
	if not NetworkManager.active:
		return
	if multiplayer.is_server():
		_apply(1, verb, args)
	else:
		request_action.rpc_id(1, verb, args)

@rpc("any_peer", "reliable")
func request_action(verb: String, args: Dictionary) -> void:
	_apply(multiplayer.get_remote_sender_id(), verb, args)

func _apply(sender: int, verb: String, args: Dictionary) -> void:
	if world == null or not multiplayer.is_server() or not world.state.players.has(str(sender)):
		return
	var now := Time.get_ticks_msec()
	if now - int(limits.get(sender, 0)) < 80 or args.size() > 12 or var_to_bytes(args).size() > 2048:
		return
	limits[sender] = now
	var success: bool = world.action(sender, verb, args)
	if sender == 1:
		action_feedback.emit(success)
	else:
		action_result.rpc_id(sender, success)
	if success:
		print("[action] peer=", sender, " verb=", verb)

@rpc("authority", "reliable")
func action_result(success: bool) -> void:
	action_feedback.emit(success)

func move_input(direction: Vector2) -> void:
	if not NetworkManager.active:
		return
	if multiplayer.is_server():
		_move(1, direction)
	else:
		request_move.rpc_id(1, direction)

@rpc("any_peer", "call_remote", "unreliable_ordered", 1)
func request_move(direction: Vector2) -> void:
	_move(multiplayer.get_remote_sender_id(), direction)

func _move(sender: int, direction: Vector2) -> void:
	if world == null or not multiplayer.is_server() or not is_finite(direction.x) or not is_finite(direction.y):
		return
	var avatar = avatars.get_node_or_null(str(sender))
	if avatar != null:
		avatar.direction = direction.limit_length()
		avatar.input_age = 0.0

func _physics_process(delta: float) -> void:
	if world == null or not multiplayer.is_server():
		return
	for avatar in avatars.get_children():
		var player: Dictionary = world.state.players.get(str(avatar.peer_id), {})
		if player.is_empty():
			continue
		var pos: Array = player.position
		if avatar.position.distance_to(Vector3(pos[0], 0, pos[2])) > 4.0:
			avatar.position = Vector3(pos[0], 0, pos[2])
		player.position = [avatar.position.x, 0.0, avatar.position.z]
		avatar.speed = 3.0 if float(player.stats.get("stamina", 100)) < 20 else 5.0
		avatar.collision_mask = 0 if player.get("ghost", false) else 1
		if float(player.get("beast_time", 0)) > 0:
			avatar.speed *= 1.5
	world.step(delta)
	if world.state.get("reset_requested", false):
		end_session.rpc("WORLD_RESET")
		return
	if int(world.state.clock.day) != last_day:
		last_day = int(world.state.clock.day)
		save()
	elapsed += delta
	if elapsed >= 0.1:
		elapsed = 0.0
		_publish()

func _publish() -> void:
	state = world.snapshot()
	state_received.emit(state)
	var patch: Dictionary = {}
	for section in state:
		if section in ["players", "clock", "events"] or state[section] != sent_sections.get(section):
			patch[section] = state[section]
	sent_sections = state.duplicate(true)
	if not multiplayer.get_peers().is_empty():
		receive_state.rpc(patch, false)

@rpc("authority", "call_remote", "reliable", 2)
func receive_state(data: Dictionary, full: bool) -> void:
	if full:
		state = data
	else:
		state.merge(data, true)
	state_received.emit(state)

@rpc("authority", "call_local", "reliable")
func end_session(message: String) -> void:
	stop()
	NetworkManager.leave()
	ended.emit(message)

func _peer_left(peer_id: int) -> void:
	if world == null or not multiplayer.is_server():
		return
	world.remove_player(peer_id)
	var avatar := avatars.get_node_or_null(str(peer_id))
	if avatar != null:
		avatar.queue_free()
