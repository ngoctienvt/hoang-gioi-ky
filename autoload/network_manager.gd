extends Node
## ENet transport. Gameplay RPCs live on the server-owned Main node.
signal joined
signal disconnected(message: String)
const DEFAULT_PORT := 24565
const MAX_PLAYERS := 4
var player_name := ""
var active := false

func _ready() -> void:
	multiplayer.connected_to_server.connect(func():
		print("[network] connected_to_server")
		joined.emit())
	multiplayer.connection_failed.connect(func(): leave(); disconnected.emit("CONNECTION_FAILED"))
	multiplayer.server_disconnected.connect(func(): leave(); disconnected.emit("HOST_DISCONNECTED"))
	multiplayer.peer_connected.connect(func(id): print("[network] peer_connected ", id))
	multiplayer.peer_disconnected.connect(func(id): print("[network] peer_disconnected ", id))

func host(display_name: String) -> Error:
	leave()
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(DEFAULT_PORT, MAX_PLAYERS - 1)
	if error != OK:
		push_warning("[network] host: " + error_string(error))
		return error
	player_name = clean_name(display_name)
	multiplayer.multiplayer_peer = peer
	active = true
	print("[network] hosting port ", DEFAULT_PORT)
	return OK

func join(address: String, display_name: String) -> Error:
	if address.strip_edges().is_empty() or address.length() > 253:
		return ERR_INVALID_PARAMETER
	leave()
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(address.strip_edges(), DEFAULT_PORT)
	if error != OK:
		return error
	player_name = clean_name(display_name)
	multiplayer.multiplayer_peer = peer
	active = true
	return OK

func leave() -> void:
	if active:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	active = false

func clean_name(value: String) -> String:
	return value.strip_edges().replace("\n", " ").replace("\r", " ").left(24)
