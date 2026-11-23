extends Node
## Real two-process ENet probe, enabled only through --probe user argument.
var main
var elapsed := 0.0
var checks := 0
var saw_two := false
var moved := false
var inventory_checked := false
var target_uid := -1
var before_count := 0

func _process(delta: float) -> void:
	elapsed += delta
	var session = main.session
	var state: Dictionary = session.state
	if not state.is_empty():
		saw_two = saw_two or state.get("players", {}).size() >= 2
		var local_id := str(multiplayer.get_unique_id())
		var player: Dictionary = state.get("players", {}).get(local_id, {})
		if not player.is_empty() and not multiplayer.is_server():
			moved = moved or float(player.position[0]) > 2.0
			if elapsed < 4:
				session.move_input(Vector2.RIGHT)
			else:
				session.move_input(Vector2.ZERO)
			if elapsed > 4 and target_uid == -1:
				for drop in state.get("drops", []):
					var p: Array = drop.position
					if Vector2(p[0] - player.position[0], p[2] - player.position[2]).length() < 2.8:
						target_uid = int(drop.uid)
						before_count = _count(player)
						session.intent("pickup", {"uid": target_uid})
						break
			if target_uid != -1 and _count(player) > before_count:
				inventory_checked = true
		elif multiplayer.is_server():
			for id in state.get("players", {}):
				if str(id) != "1" and float(state.players[id].position[0]) > 2:
					moved = true
	if elapsed > (12 if multiplayer.is_server() else 8):
		checks = int(saw_two) + int(moved)
		print("[probe] saw_two=", saw_two, " moved=", moved, " pickup=", inventory_checked)
		if multiplayer.is_server():
			session.save()
		main.session.stop()
		NetworkManager.leave()
		get_tree().quit(0 if checks == 2 else 1)

func _count(player: Dictionary) -> int:
	var count := 0
	for slot in player.get("inventory", {}).get("slots", []):
		count += int(slot.get("count", 0))
	return count
