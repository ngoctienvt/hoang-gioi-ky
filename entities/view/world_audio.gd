extends Node

var _last_event_time := -1.0
var _last_event_sig := ""
var _prev_phase := ""
var _prev_hp := -1.0
var _prev_ghost := false
var _prev_pos := Vector2.INF
var _step_accum := 0.0
var _combat_timer := 0.0
var _warning_timer := 0.0
var _whisper_timer := 0.0
var _hungry_timer := 0.0
var _thunder_timer := 0.0
var _prev_warning_count := 0


func reset() -> void:
	_last_event_time = -1.0
	_last_event_sig = ""
	_prev_phase = ""
	_prev_hp = -1.0
	_prev_ghost = false
	_prev_pos = Vector2.INF
	_step_accum = 0.0
	_combat_timer = 0.0
	_warning_timer = 0.0
	_whisper_timer = 0.0
	_hungry_timer = 0.0
	_thunder_timer = 0.0
	_prev_warning_count = 0
	var am := _audio()
	if am != null:
		am.stop_ambient()
		am.stop_music(0.8)


func _audio() -> Node:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("AudioManager")


func update(state: Dictionary, peer: int, delta: float) -> void:
	var am := _audio()
	if am == null or state.is_empty():
		return

	_warning_timer = maxf(0.0, _warning_timer - delta)
	_whisper_timer = maxf(0.0, _whisper_timer - delta)
	_hungry_timer = maxf(0.0, _hungry_timer - delta)
	_combat_timer = maxf(0.0, _combat_timer - delta)
	_thunder_timer = maxf(0.0, _thunder_timer - delta)

	var player: Dictionary = state.get("players", {}).get(str(peer), {})
	var clock: Dictionary = state.get("clock", {})
	var phase := str(clock.get("phase", "day"))
	var season := str(clock.get("season", "autumn"))

	_process_events(state, player, peer, am)
	_process_phase_stingers(phase, am)
	_process_player_state(state, player, delta, am)
	_process_weather_sfx(state, am)
	_process_music(state, player, phase, season, am)
	_process_ambient(state, player, phase, season, delta, am)


func _process_events(state: Dictionary, player: Dictionary, peer: int, am: Node) -> void:
	var events: Array = state.get("events", [])
	if events.is_empty():
		return
	for ev in events:
		if not ev is Dictionary:
			continue
		var ev_time := float(ev.get("time", 0.0))
		var sig := "%s|%s|%s" % [str(ev_time), str(ev.get("event", "")), str(ev.get("details", {}))]
		if ev_time < _last_event_time:
			continue
		if is_equal_approx(ev_time, _last_event_time) and sig == _last_event_sig:
			continue
		_last_event_time = ev_time
		_last_event_sig = sig
		var ev_name := str(ev.get("event", ""))
		var details: Dictionary = ev.get("details", {})
		var ev_peer := int(details.get("peer", -1))
		var verb := str(details.get("verb", ""))
		if ev_name == "rejected":
			if ev_peer == peer:
				am.play_ui("ui_error")
			continue
		if ev_name != "action":
			continue
		_play_verb_sfx(verb, player, am)


func _play_verb_sfx(verb: String, player: Dictionary, am: Node) -> void:
	match verb:
		"work":
			var hand_id := str(player.get("inventory", {}).get("equipment", {}).get("hand", {}).get("id", ""))
			if "axe" in hand_id and not "pick" in hand_id:
				am.play_sfx_variant(["chop_1", "chop_2", "chop_3"], 0.08)
			elif "pick" in hand_id:
				am.play_sfx("mine_1", 0.08)
			elif "shovel" in hand_id:
				am.play_sfx_variant(["dig_1", "dig_2", "dig_3"], 0.08)
			else:
				am.play_sfx_variant(["harvest_1", "harvest_2", "harvest_sticks"], 0.08)
		"pickup":
			am.play_sfx("pickup", 0.06)
		"drop":
			am.play_sfx("drop", 0.06)
		"equip", "unequip":
			am.play_sfx("equip", 0.05)
		"use":
			am.play_sfx_variant(["eat_1", "eat_2", "eat_3"], 0.07)
		"craft":
			am.play_sfx("craft", 0.04)
		"place":
			am.play_sfx("place", 0.05)
		"fuel":
			am.play_sfx("fuel_fire", 0.06)
		"plant":
			am.play_sfx("plant", 0.06)
		"roast":
			am.play_sfx("cook_sizzle", 0.05)
		"cook", "insert", "take":
			am.play_sfx("make_soup", 0.05)
		"attack":
			_combat_timer = 6.0
			am.play_sfx_variant(["swing_1", "swing_2"], 0.08)
			am.play_sfx_variant(["hit_1", "hit_2"], 0.08)
		"ability", "throw_talisman", "start_awakening", "offer_altar", "unlock_skill":
			am.play_sfx_variant(["spell_cast", "magic_sparkle"], 0.05)
		"teleport", "enter_secret_realm", "exit_secret_realm":
			am.play_sfx("portal_open", 0.04)
		"revive":
			am.play_sfx("ghost_spawn", 0.04)
		"summon_boss":
			_combat_timer = 8.0
			am.play_sfx("deathpoof", 0.04)


func _process_phase_stingers(phase: String, am: Node) -> void:
	if _prev_phase.is_empty():
		_prev_phase = phase
		return
	if phase != _prev_phase:
		if phase == "day":
			am.play_stinger("stinger_dawn")
		elif phase == "dusk":
			am.play_stinger("stinger_dusk")
		_prev_phase = phase


func _process_player_state(state: Dictionary, player: Dictionary, _delta: float, am: Node) -> void:
	if player.is_empty():
		return
	var stats: Dictionary = player.get("stats", {})
	var hp := float(stats.get("health", 100.0))
	var is_ghost := bool(player.get("ghost", false))

	if _prev_hp >= 0.0 and hp < _prev_hp - 0.5 and not is_ghost:
		_combat_timer = 6.0
		am.play_sfx_variant(["player_hurt_1", "player_hurt_2"], 0.07)
	_prev_hp = hp

	if not _prev_ghost and is_ghost:
		am.play_sfx("player_death", 0.03)
		am.play_sfx("death_trumpet", 0.02)
	_prev_ghost = is_ghost

	if float(player.get("darkness", 0.0)) > 1.0 and _warning_timer <= 0.0:
		am.play_sfx("darkness_warn", 0.05)
		_warning_timer = 2.4

	var dao := float(stats.get("dao", 100.0))
	if dao < 30.0 and _whisper_timer <= 0.0:
		am.play_sfx_variant(["whisper_1", "whisper_2", "whisper_3"], 0.06, -3.0)
		_whisper_timer = 5.0

	var stamina := float(stats.get("stamina", 100.0))
	if stamina < 20.0 and not is_ghost and _hungry_timer <= 0.0:
		am.play_sfx("hungry", 0.04, -3.0)
		_hungry_timer = 16.0

	# Footsteps based on XZ travel
	var pos_arr: Array = player.get("position", [0.0, 0.0, 0.0])
	var pos := Vector2(float(pos_arr[0]), float(pos_arr[2]))
	if _prev_pos.is_finite() and not is_ghost:
		var moved := pos.distance_to(_prev_pos)
		if moved > 0.001 and moved < 4.0:
			_step_accum += moved
			if _step_accum >= 1.35:
				_step_accum = 0.0
				_play_footstep(state, player, am)
	_prev_pos = pos


func _play_footstep(state: Dictionary, player: Dictionary, am: Node) -> void:
	var biome := str(player.get("biome", "bamboo_forest"))
	var season := str(state.get("clock", {}).get("season", "autumn"))
	if bool(player.get("in_mud", false)) or biome == "nether_swamp":
		am.play_sfx_variant(["step_mud_1", "step_mud_2", "step_mud_3"], 0.08, -8.0)
	elif biome == "frost_peaks" or season == "winter":
		am.play_sfx_variant(["step_snow_1", "step_snow_2", "step_snow_3"], 0.08, -8.0)
	elif biome == "bamboo_forest":
		am.play_sfx_variant(["step_woods_1", "step_woods_2", "step_woods_3"], 0.08, -8.0)
	elif biome in ["crimson_volcano", "ancient_ruins", "thunder_gorge"]:
		am.play_sfx_variant(["step_dirt_1", "step_dirt_2", "step_dirt_3"], 0.08, -8.0)
	else:
		am.play_sfx_variant(["step_grass_1", "step_grass_2", "step_grass_3"], 0.08, -8.0)


func _process_weather_sfx(state: Dictionary, am: Node) -> void:
	var weather: Dictionary = state.get("weather", {})
	var warnings: Array = weather.get("warnings", [])
	if warnings.size() > _prev_warning_count:
		am.play_sfx("thunder_close", 0.06, -2.0)
	_prev_warning_count = warnings.size()

	if str(weather.get("kind", "clear")) == "storm" and _thunder_timer <= 0.0:
		am.play_sfx("thunder_far", 0.08, -4.0)
		_thunder_timer = randf_range(8.0, 16.0)


func _process_music(state: Dictionary, player: Dictionary, phase: String, season: String, am: Node) -> void:
	if player.is_empty():
		return
	var p_arr: Array = player.get("position", [0.0, 0.0, 0.0])
	var p_pos := Vector2(float(p_arr[0]), float(p_arr[2]))

	var boss_near := false
	var hostile_near := false
	for c in state.get("creatures", []):
		if not c is Dictionary or str(c.get("state", "")) == "dead":
			continue
		var c_arr: Array = c.get("position", [0.0, 0.0, 0.0])
		var dist := p_pos.distance_to(Vector2(float(c_arr[0]), float(c_arr[2])))
		var c_kind := str(c.get("kind", ""))
		if c_kind.begins_with("boss_") and dist <= 28.0:
			boss_near = true
			break
		if dist <= 14.0 and str(c.get("state", "")) in ["chase", "attack", "aggro"]:
			hostile_near = true

	if boss_near:
		am.play_music("boss", 1.0)
	elif hostile_near or _combat_timer > 0.0:
		am.play_music("combat", 1.0)
	elif bool(player.get("in_secret_realm", false)):
		am.play_music("secret_realm", 1.5)
	elif phase == "night":
		am.stop_music(2.0)
	else:
		var track := "season_" + season
		if not am.MUSIC_PATHS.has(track):
			track = "season_autumn"
		am.play_music(track, 2.0)


func _process_ambient(state: Dictionary, player: Dictionary, phase: String, season: String, delta: float, am: Node) -> void:
	var biome := str(player.get("biome", "bamboo_forest"))
	var is_night := phase == "night"
	var biome_track := "meadow_night" if is_night else "meadow_day"
	if biome == "nether_swamp":
		biome_track = "marsh_night" if is_night else "marsh_day"
	elif biome in ["crimson_volcano", "frost_peaks", "thunder_gorge", "ancient_ruins"]:
		biome_track = "rocky_night" if is_night else "rocky_day"

	var wkind := str(state.get("weather", {}).get("kind", "clear"))
	var weather_track := ""
	var weather_gain := 0.0
	if wkind == "rain":
		weather_track = "rain"
		weather_gain = 0.70
	elif wkind == "storm":
		weather_track = "rain"
		weather_gain = 0.95
	elif wkind == "snow":
		weather_track = "wind"
		weather_gain = 0.75
	elif season == "winter":
		weather_track = "wind"
		weather_gain = 0.25

	var p_arr: Array = player.get("position", [0.0, 0.0, 0.0])
	var p_pos := Vector2(float(p_arr[0]), float(p_arr[2]))
	var min_fire_dist := 999.0
	var hand_id := str(player.get("inventory", {}).get("equipment", {}).get("hand", {}).get("id", ""))
	if hand_id == "torch":
		min_fire_dist = 1.5
	for s in state.get("structures", []):
		if not s is Dictionary:
			continue
		var skind := str(s.get("kind", ""))
		if skind in ["campfire", "firepit", "alchemy_furnace"] and float(s.get("fuel", 0.0)) > 0.0:
			var s_arr: Array = s.get("position", [0.0, 0.0, 0.0])
			var d := p_pos.distance_to(Vector2(float(s_arr[0]), float(s_arr[2])))
			min_fire_dist = minf(min_fire_dist, d)
	var fire_gain := clampf(1.0 - min_fire_dist / 12.0, 0.0, 0.85)

	var dao := float(player.get("stats", {}).get("dao", 100.0))
	var sanity_gain := clampf((40.0 - dao) / 35.0, 0.0, 0.85) if dao < 40.0 else 0.0

	am.set_ambient_state(biome_track, weather_track, weather_gain, fire_gain, sanity_gain, delta)
