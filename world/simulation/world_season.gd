extends RefCounted

const SeasonDef = preload("res://data/defs/season_def.gd")
const ORDER := ["autumn", "winter", "spring", "summer"]
static var _cache: Dictionary = {}


static func get_def(season_id: String) -> SeasonDef:
	if _cache.has(season_id):
		return _cache[season_id]
	var path := "res://data/seasons/%s.tres" % season_id
	var def: SeasonDef = load(path) if ResourceLoader.exists(path) else null
	if def != null:
		_cache[season_id] = def
	return def


static func season_length(world, season_id: String) -> int:
	var lengths: Dictionary = world.state.get("options", {}).get("season_lengths", {})
	var def := get_def(season_id)
	var fallback := def.default_length if def != null else 20
	return maxi(1, int(lengths.get(season_id, fallback)))


static func update_clock(world) -> void:
	var dl: float = world.day_length()
	var elapsed_val: float = float(world.state.clock.get("elapsed", 0.0))
	var day: int = int(elapsed_val / dl) + 1
	world.state.clock["day"] = day

	var seasons_enabled: bool = bool(world.state.get("options", {}).get("seasons", true))
	var season_id := "autumn"
	var season_day := day
	var length := 20
	var days_to_next := 20
	var season_warning := false
	var day_seg := 8
	var dusk_seg := 6
	var night_seg := 2

	if seasons_enabled:
		var cycle_days := 0
		for sid in ORDER:
			cycle_days += season_length(world, sid)
		var rem := (day - 1) % maxi(1, cycle_days)
		for sid in ORDER:
			var l := season_length(world, sid)
			if rem < l:
				season_id = sid
				season_day = rem + 1
				length = l
				break
			rem -= l
		days_to_next = length - season_day + 1
		season_warning = days_to_next <= 3
		var def := get_def(season_id)
		if def != null:
			day_seg = def.day_segments
			dusk_seg = def.dusk_segments
			night_seg = def.night_segments

	var fraction := fmod(elapsed_val, dl) / dl
	var day_end := float(day_seg) / 16.0
	var dusk_end := float(day_seg + dusk_seg) / 16.0
	var phase := "day" if fraction < day_end else ("dusk" if fraction < dusk_end else "night")

	world.state.clock["phase"] = phase
	world.state.clock["season"] = season_id
	world.state.clock["season_day"] = season_day
	world.state.clock["days_to_next_season"] = days_to_next
	world.state.clock["season_warning"] = season_warning
	world.state.clock["day_segments"] = day_seg
	world.state.clock["dusk_segments"] = dusk_seg
	world.state.clock["night_segments"] = night_seg

	GameClock.season = season_id
	GameClock.season_day = season_day
	GameClock.days_to_next_season = days_to_next
	GameClock.day_segments = day_seg
	GameClock.dusk_segments = dusk_seg
	GameClock.night_segments = night_seg
