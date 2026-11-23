extends RefCounted

const CONFLICTS := {"fire": "ice", "ice": "fire", "yin": "spirit", "spirit": "yin"}
const WINDOW := 60.0


static func record_and_check(world, player: Dictionary, element: String) -> bool:
	var now: float = world.elapsed()
	var history: Array = _prune(player, now)
	var conflict_elem: String = str(CONFLICTS.get(element, ""))
	var conflicted := false
	for entry in history:
		if str(entry.get("element", "")) == conflict_elem:
			conflicted = true
			break
	history.append({"element": element, "time": now})
	player["devour_history"] = history
	if conflicted:
		var max_hp := float(player.stats.get("max_health", 150.0))
		player.stats["health"] = clampf(float(player.stats.get("health", max_hp)) - 25.0, 0.0, max_hp)
		player.stats["dao"] = maxf(0.0, float(player.stats.get("dao", 100.0)) - 20.0)
		world.log_event("devour_conflict", {"name": player.name, "element": element})
		if float(player.stats.health) <= 0.0:
			world.life.die(world, player)
	return conflicted


static func step(world, player: Dictionary, _stats, delta: float, modifiers: Dictionary) -> void:
	_prune(player, world.elapsed())
	if world.Effects.has(player, "nausea"):
		modifiers["dao"] = float(modifiers.get("dao", 0.0)) - 0.8 * delta


static func _prune(player: Dictionary, now: float) -> Array:
	var raw = player.get("devour_history", [])
	var kept: Array = []
	if raw is Array:
		for entry in raw:
			if entry is Dictionary and now - float(entry.get("time", 0.0)) <= WINDOW:
				kept.append(entry)
	player["devour_history"] = kept
	return kept
