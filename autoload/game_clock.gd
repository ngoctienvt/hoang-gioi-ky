extends Node
const DAY_LENGTH_SECONDS: float = 480.0
var day_length: float = 480.0
var elapsed: float = 0.0
var day: int = 1
var season: String = "autumn"
var season_day: int = 1
var days_to_next_season: int = 20
var day_segments: int = 8
var dusk_segments: int = 6
var night_segments: int = 2

func phase() -> String:
	var fraction = elapsed / maxf(1.0, day_length)
	var day_end := float(day_segments) / 16.0
	var dusk_end := float(day_segments + dusk_segments) / 16.0
	return "day" if fraction < day_end else ("dusk" if fraction < dusk_end else "night")

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
	return {
		"day": day,
		"elapsed": elapsed,
		"day_length": day_length,
		"season": season,
		"season_day": season_day,
		"days_to_next_season": days_to_next_season,
		"day_segments": day_segments,
		"dusk_segments": dusk_segments,
		"night_segments": night_segments,
	}

func from_dict(state: Dictionary) -> void:
	day_length = clampf(float(state.get("day_length", 480.0)), 30.0, 86400.0)
	elapsed = clampf(float(state.get("elapsed", 0.0)), 0.0, day_length - 0.001)
	day = maxi(1, int(state.get("day", 1)))
	season = str(state.get("season", "autumn"))
	season_day = maxi(1, int(state.get("season_day", 1)))
	days_to_next_season = maxi(0, int(state.get("days_to_next_season", 20)))
	day_segments = clampi(int(state.get("day_segments", 8)), 0, 16)
	dusk_segments = clampi(int(state.get("dusk_segments", 6)), 0, 16)
	night_segments = clampi(int(state.get("night_segments", 2)), 0, 16)
