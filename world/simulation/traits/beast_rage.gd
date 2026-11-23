extends RefCounted


static func is_full_moon(world) -> bool:
	var day := int(world.state.get("clock", {}).get("day", 1))
	var phase := str(world.state.get("clock", {}).get("phase", "day"))
	return day % 7 == 0 and phase == "night"


static func step(world, player: Dictionary, stats, delta: float, modifiers: Dictionary) -> void:
	var gain := 0.0
	if stats.stamina < 30.0:
		gain += 2.0
	if stats.dao < 30.0:
		gain += 2.0
	if world.Weather.player_weather(world, player) in ["rain", "storm"]:
		gain += 1.5
	if is_full_moon(world):
		gain = (gain + 1.5) * 2.0
	if gain > 0.0:
		player["rage"] = minf(100.0, float(player.get("rage", 0.0)) + gain * delta)
	elif not player.get("mad", false):
		player["rage"] = maxf(0.0, float(player.get("rage", 0.0)) - 4.0 * delta)
	var enraged: bool = stats.stamina <= 5.0 or stats.dao <= 5.0 or float(player.get("rage", 0.0)) >= 100.0
	if enraged and float(player.get("beast_time", 0.0)) <= 0.0:
		player.mad = true
		player.beast_time = 12.0
		player["rage"] = 100.0
		world.life.clear_hand(world, player)
	elif float(player.get("beast_time", 0.0)) <= 0.0:
		if player.get("mad", false):
			player.mad = false
			player["rage"] = 0.0
	if float(player.get("beast_time", 0.0)) > 0.0:
		modifiers["stamina"] = float(modifiers.get("stamina", 0.0)) - delta * 2.0
	if player.get("mad", false) and float(player.get("attack_cd", 0.0)) <= 0.0:
		for peer in world.state.players:
			var other: Dictionary = world.state.players[peer]
			if other != player and not other.ghost and world.near(player, other, 2.8):
				world.Combat.attack(world, player, {"peer_id": int(peer)})
				break
