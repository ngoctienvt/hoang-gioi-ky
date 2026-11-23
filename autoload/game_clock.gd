extends Node
const DAY_LENGTH_SECONDS: float = 480.0
var day_length: float = 480.0
var elapsed: float = 0.0
var day: int = 1
func phase() -> String:
	var fraction = elapsed / maxf(1.0, day_length)
	return "day" if fraction < 0.5 else ("dusk" if fraction < 0.875 else "night")
func advance(delta: float) -> void:
	if not is_finite(delta) or delta <= 0.0:
		return
	var previous = phase()
	elapsed += delta
	while elapsed >= maxf(1.0, day_length):
		elapsed -= maxf(1.0, day_length)
		day += 1
		EventBus.day_started.emit(day)
	if phase() != previous:
		EventBus.day_phase_changed.emit(StringName(phase()))
func to_dict() -> Dictionary:
	return {"day": day, "elapsed": elapsed, "day_length": day_length}
func from_dict(state: Dictionary) -> void:
	day_length = clampf(float(state.get("day_length", 480.0)), 30.0, 86400.0)
	elapsed = clampf(float(state.get("elapsed", 0.0)), 0.0, day_length - 0.001)
	day = maxi(1, int(state.get("day", 1)))
