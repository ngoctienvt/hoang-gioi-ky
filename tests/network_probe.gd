extends Node
## Real multi-process ENet probe, enabled only through the --probe user argument.
## Host: waits for every client, places one twig a few metres from each client, measures the bytes
## ENet sends while clients are connected and fails if the average per client exceeds the budget.
## Client: walks right, then walks to the twig and picks it up; the pickup only counts once the
## host-replicated inventory shows the extra item.

const RUN_SECONDS_HOST := 14.0
const RUN_SECONDS_CLIENT := 11.0
const MAX_AVG_KBPS_PER_CLIENT := 48.0
const PICKUP_RANGE := 2.0
## Players all spawn on the same spot and push each other, so "moved" is any 1.5 m displacement.
const MOVE_DISTANCE := 1.5

var main
var elapsed := 0.0
var expected_clients := 1
var saw_all := false
var moved := false
var picked_up := false
var drops_placed := false
var retry_at := 0.0
var before_count := -1
var sent_bytes := 0
var received_bytes := 0
var measured_seconds := 0.0
var is_host := false
var first_seen: Dictionary = {}  # player id -> Vector2 where this process first saw them
var moved_ids: Dictionary = {}


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	# Decided once: after the host leaves, a client's multiplayer API reports itself as server.
	is_host = "--host" in args
	var idx := args.find("--clients")
	if idx >= 0 and idx + 1 < args.size():
		expected_clients = maxi(1, int(args[idx + 1]))


func _process(delta: float) -> void:
	elapsed += delta
	var session = main.session
	var state: Dictionary = session.state
	if not state.is_empty():
		if is_host:
			_host_step(session, state, delta)
		else:
			_client_step(session, state)
	if elapsed > (RUN_SECONDS_HOST if is_host else RUN_SECONDS_CLIENT):
		_finish(session)


func _host_step(session, state: Dictionary, delta: float) -> void:
	var players: Dictionary = state.get("players", {})
	saw_all = saw_all or players.size() >= 1 + expected_clients
	for id in players:
		if str(id) != "1" and _has_moved(str(id), players[id]):
			moved_ids[str(id)] = true
	moved = moved_ids.size() >= expected_clients
	if moved and not drops_placed and elapsed > 5.0:
		drops_placed = true
		for id in players:
			if str(id) != "1":
				var p: Array = players[id].position
				session.world.drop_item("twig", 1, [float(p[0]) + 1.5, 0.0, float(p[2])])
	if saw_all:
		_sample_enet(delta)


func _client_step(session, state: Dictionary) -> void:
	saw_all = saw_all or state.get("players", {}).size() >= 2
	var player: Dictionary = state.get("players", {}).get(str(multiplayer.get_unique_id()), {})
	if player.is_empty():
		return
	var pos := Vector2(float(player.position[0]), float(player.position[2]))
	moved = moved or _has_moved(str(multiplayer.get_unique_id()), player)
	if before_count < 0:
		before_count = _count(player)
	if elapsed < 4.0:
		session.move_input(Vector2.RIGHT)
		return
	var twig := _nearest_twig(state, pos)
	if twig.is_empty():
		session.move_input(Vector2.ZERO)
	else:
		var to := Vector2(float(twig.position[0]), float(twig.position[2])) - pos
		if to.length() > PICKUP_RANGE:
			session.move_input(to.normalized())
		else:
			session.move_input(Vector2.ZERO)
			# The host may reject a request (rate limit, work cooldown); retry until the twig is gone.
			if elapsed >= retry_at:
				retry_at = elapsed + 0.5
				session.intent("pickup", {"uid": int(twig.uid)})
	picked_up = picked_up or _count(player) > before_count


func _has_moved(id: String, player: Dictionary) -> bool:
	var pos := Vector2(float(player.position[0]), float(player.position[2]))
	if not first_seen.has(id):
		first_seen[id] = pos
	return pos.distance_to(first_seen[id]) >= MOVE_DISTANCE


func _nearest_twig(state: Dictionary, pos: Vector2) -> Dictionary:
	var best: Dictionary = {}
	var best_d := 12.0
	for drop in state.get("drops", []):
		if str(drop.get("id", "")) != "twig":
			continue
		var d := Vector2(float(drop.position[0]), float(drop.position[2])).distance_to(pos)
		if d < best_d:
			best_d = d
			best = drop
	return best


func _sample_enet(delta: float) -> void:
	var mp_peer := multiplayer.multiplayer_peer
	if not mp_peer is ENetMultiplayerPeer or mp_peer.host == null:
		return
	sent_bytes += int(mp_peer.host.pop_statistic(ENetConnection.HOST_TOTAL_SENT_DATA))
	received_bytes += int(mp_peer.host.pop_statistic(ENetConnection.HOST_TOTAL_RECEIVED_DATA))
	measured_seconds += delta


func _finish(session) -> void:
	var ok := saw_all and moved
	if is_host:
		var per_client_kbps := float(sent_bytes) / maxf(measured_seconds, 0.001) / 1024.0 / float(expected_clients)
		var within := measured_seconds > 1.0 and per_client_kbps <= MAX_AVG_KBPS_PER_CLIENT
		print("[probe] enet clients=%d seconds=%.1f sent_kb=%.1f received_kb=%.1f per_client_kbps=%.2f within_budget=%s" % [
			expected_clients, measured_seconds, sent_bytes / 1024.0, received_bytes / 1024.0, per_client_kbps, within])
		ok = ok and drops_placed and within
		session.save()
	else:
		ok = ok and picked_up
	print("[probe] saw_all=", saw_all, " moved=", moved, " pickup=", picked_up, " ok=", ok)
	set_process(false)
	session.stop()
	NetworkManager.leave()
	main.quit_game(0 if ok else 1)


func _count(player: Dictionary) -> int:
	var count := 0
	for slot in player.get("inventory", {}).get("slots", []):
		if slot is Dictionary:
			count += int(slot.get("count", 0))
	return count
