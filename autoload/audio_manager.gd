extends Node

const BUS_MUSIC := &"Music"
const BUS_AMBIENT := &"Ambient"
const BUS_SFX := &"SFX"
const SFX_POOL_SIZE := 12

const MUSIC_PATHS := {
	"menu_theme": "res://assets/audio/music/menu_theme.ogg",
	"season_autumn": "res://assets/audio/music/season_autumn.ogg",
	"season_winter": "res://assets/audio/music/season_winter.ogg",
	"season_spring": "res://assets/audio/music/season_spring.ogg",
	"season_summer": "res://assets/audio/music/season_summer.ogg",
	"secret_realm": "res://assets/audio/music/secret_realm.ogg",
	"combat": "res://assets/audio/music/combat.ogg",
	"boss": "res://assets/audio/music/boss.ogg",
	"stinger_dawn": "res://assets/audio/music/stinger_dawn.ogg",
	"stinger_dusk": "res://assets/audio/music/stinger_dusk.ogg",
}

const NON_LOOPING_MUSIC := {
	"stinger_dawn": true,
	"stinger_dusk": true,
}

const AMBIENT_PATHS := {
	"meadow_day": "res://assets/audio/ambient/meadow_day.ogg",
	"meadow_night": "res://assets/audio/ambient/meadow_night.ogg",
	"marsh_day": "res://assets/audio/ambient/marsh_day.ogg",
	"marsh_night": "res://assets/audio/ambient/marsh_night.ogg",
	"rocky_day": "res://assets/audio/ambient/rocky_day.ogg",
	"rocky_night": "res://assets/audio/ambient/rocky_night.ogg",
	"rain": "res://assets/audio/ambient/rain.ogg",
	"wind": "res://assets/audio/ambient/wind.ogg",
	"campfire": "res://assets/audio/ambient/campfire.ogg",
	"sanity_loop": "res://assets/audio/ambient/sanity_loop.ogg",
}

const SFX_PATHS := {
	"step_grass_1": "res://assets/audio/sfx/step_grass_1.wav",
	"step_grass_2": "res://assets/audio/sfx/step_grass_2.wav",
	"step_grass_3": "res://assets/audio/sfx/step_grass_3.wav",
	"step_dirt_1": "res://assets/audio/sfx/step_dirt_1.wav",
	"step_dirt_2": "res://assets/audio/sfx/step_dirt_2.wav",
	"step_dirt_3": "res://assets/audio/sfx/step_dirt_3.wav",
	"step_snow_1": "res://assets/audio/sfx/step_snow_1.wav",
	"step_snow_2": "res://assets/audio/sfx/step_snow_2.wav",
	"step_snow_3": "res://assets/audio/sfx/step_snow_3.wav",
	"step_mud_1": "res://assets/audio/sfx/step_mud_1.wav",
	"step_mud_2": "res://assets/audio/sfx/step_mud_2.wav",
	"step_mud_3": "res://assets/audio/sfx/step_mud_3.wav",
	"step_woods_1": "res://assets/audio/sfx/step_woods_1.wav",
	"step_woods_2": "res://assets/audio/sfx/step_woods_2.wav",
	"step_woods_3": "res://assets/audio/sfx/step_woods_3.wav",
	"chop_1": "res://assets/audio/sfx/chop_1.wav",
	"chop_2": "res://assets/audio/sfx/chop_2.wav",
	"chop_3": "res://assets/audio/sfx/chop_3.wav",
	"tree_fall": "res://assets/audio/sfx/tree_fall.wav",
	"mine_1": "res://assets/audio/sfx/mine_1.wav",
	"stone_break": "res://assets/audio/sfx/stone_break.wav",
	"dig_1": "res://assets/audio/sfx/dig_1.wav",
	"dig_2": "res://assets/audio/sfx/dig_2.wav",
	"dig_3": "res://assets/audio/sfx/dig_3.wav",
	"harvest_1": "res://assets/audio/sfx/harvest_1.wav",
	"harvest_2": "res://assets/audio/sfx/harvest_2.wav",
	"harvest_sticks": "res://assets/audio/sfx/harvest_sticks.wav",
	"plant": "res://assets/audio/sfx/plant.wav",
	"swing_1": "res://assets/audio/sfx/swing_1.wav",
	"swing_2": "res://assets/audio/sfx/swing_2.wav",
	"hit_1": "res://assets/audio/sfx/hit_1.wav",
	"hit_2": "res://assets/audio/sfx/hit_2.wav",
	"player_hurt_1": "res://assets/audio/sfx/player_hurt_1.wav",
	"player_hurt_2": "res://assets/audio/sfx/player_hurt_2.wav",
	"player_death": "res://assets/audio/sfx/player_death.wav",
	"death_trumpet": "res://assets/audio/sfx/death_trumpet.wav",
	"pickup": "res://assets/audio/sfx/pickup.wav",
	"drop": "res://assets/audio/sfx/drop.wav",
	"equip": "res://assets/audio/sfx/equip.wav",
	"eat_1": "res://assets/audio/sfx/eat_1.wav",
	"eat_2": "res://assets/audio/sfx/eat_2.wav",
	"eat_3": "res://assets/audio/sfx/eat_3.wav",
	"craft": "res://assets/audio/sfx/craft.wav",
	"place": "res://assets/audio/sfx/place.wav",
	"cook_sizzle": "res://assets/audio/sfx/cook_sizzle.wav",
	"make_soup": "res://assets/audio/sfx/make_soup.wav",
	"fuel_fire": "res://assets/audio/sfx/fuel_fire.wav",
	"fire_out": "res://assets/audio/sfx/fire_out.wav",
	"tool_break": "res://assets/audio/sfx/tool_break.wav",
	"destroy_wood": "res://assets/audio/sfx/destroy_wood.wav",
	"spell_cast": "res://assets/audio/sfx/spell_cast.wav",
	"magic_sparkle": "res://assets/audio/sfx/magic_sparkle.wav",
	"portal_open": "res://assets/audio/sfx/portal_open.wav",
	"ghost_spawn": "res://assets/audio/sfx/ghost_spawn.wav",
	"deathpoof": "res://assets/audio/sfx/deathpoof.wav",
	"thunder_close": "res://assets/audio/sfx/thunder_close.wav",
	"thunder_far": "res://assets/audio/sfx/thunder_far.wav",
	"darkness_warn": "res://assets/audio/sfx/darkness_warn.wav",
	"whisper_1": "res://assets/audio/sfx/whisper_1.wav",
	"whisper_2": "res://assets/audio/sfx/whisper_2.wav",
	"whisper_3": "res://assets/audio/sfx/whisper_3.wav",
	"hungry": "res://assets/audio/sfx/hungry.wav",
	"ui_click": "res://assets/audio/sfx/ui_click.wav",
	"ui_error": "res://assets/audio/sfx/ui_error.wav",
	"ui_craft_open": "res://assets/audio/sfx/ui_craft_open.wav",
	"ui_craft_close": "res://assets/audio/sfx/ui_craft_close.wav",
	"ui_book_open": "res://assets/audio/sfx/ui_book_open.wav",
	"ui_chest_open": "res://assets/audio/sfx/ui_chest_open.wav",
	"ui_chest_close": "res://assets/audio/sfx/ui_chest_close.wav",
}

var _stream_cache: Dictionary = {}
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_cursor := 0

var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _stinger: AudioStreamPlayer
var _music_tween: Tween
var current_music_key := ""

var _amb_biome_a: AudioStreamPlayer
var _amb_biome_b: AudioStreamPlayer
var _amb_biome_tween: Tween
var _current_biome_track := ""

var _amb_weather: AudioStreamPlayer
var _current_weather_track := ""
var _amb_fire: AudioStreamPlayer
var _amb_sanity: AudioStreamPlayer


func _ready() -> void:
	for i in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = BUS_SFX
		player.max_polyphony = 4
		add_child(player)
		_sfx_pool.append(player)

	_music_a = _make_player(BUS_MUSIC)
	_music_b = _make_player(BUS_MUSIC)
	_stinger = _make_player(BUS_MUSIC)

	_amb_biome_a = _make_player(BUS_AMBIENT)
	_amb_biome_b = _make_player(BUS_AMBIENT)
	_amb_weather = _make_player(BUS_AMBIENT)
	_amb_fire = _make_player(BUS_AMBIENT)
	_amb_sanity = _make_player(BUS_AMBIENT)


func _exit_tree() -> void:
	release_all()


## Stops every player and drops cached streams. Playing streams hold Ogg playbacks that the audio
## server frees on its next mix, so call this a couple of frames before quitting.
func release_all() -> void:
	for tween in [_music_tween, _amb_biome_tween]:
		if tween != null and tween.is_valid():
			tween.kill()
	for child in get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
	_stream_cache.clear()
	current_music_key = ""
	_current_biome_track = ""
	_current_weather_track = ""


func _make_player(bus_name: StringName) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = bus_name
	add_child(player)
	return player


func _get_stream(path: String, looping: bool = false) -> AudioStream:
	if path.is_empty():
		return null
	var cache_key := "%s|%s" % [path, str(looping)]
	if _stream_cache.has(cache_key):
		return _stream_cache[cache_key]
	if not ResourceLoader.exists(path):
		return null
	var stream := load(path) as AudioStream
	if stream == null:
		return null
	if looping and stream is AudioStreamOggVorbis:
		var dup := stream.duplicate() as AudioStreamOggVorbis
		if dup != null:
			dup.loop = true
			stream = dup
	_stream_cache[cache_key] = stream
	return stream


func play_sfx(key: String, pitch_jitter: float = 0.06, volume_db: float = 0.0) -> void:
	var path: String = str(SFX_PATHS.get(key, ""))
	var stream := _get_stream(path, false)
	if stream == null or _sfx_pool.is_empty():
		return
	var player := _sfx_pool[_sfx_cursor]
	_sfx_cursor = (_sfx_cursor + 1) % _sfx_pool.size()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = randf_range(1.0 - pitch_jitter, 1.0 + pitch_jitter) if pitch_jitter > 0.0 else 1.0
	player.play()


func play_sfx_variant(keys: Array, pitch_jitter: float = 0.08, volume_db: float = 0.0) -> void:
	if keys.is_empty():
		return
	var chosen := str(keys[randi() % keys.size()])
	play_sfx(chosen, pitch_jitter, volume_db)


func play_ui(key: String, volume_db: float = -4.0) -> void:
	play_sfx(key, 0.02, volume_db)


func play_music(key: String, fade_secs: float = 1.5, target_db: float = -6.0) -> void:
	if key == current_music_key and _music_a != null and _music_a.playing:
		return
	var path: String = str(MUSIC_PATHS.get(key, ""))
	var should_loop := not NON_LOOPING_MUSIC.has(key)
	var stream := _get_stream(path, should_loop)
	if stream == null:
		return
	current_music_key = key
	if _music_tween != null and _music_tween.is_valid():
		_music_tween.kill()
	_music_b.stream = stream
	_music_b.volume_db = -40.0
	_music_b.play()
	if fade_secs <= 0.05:
		_music_a.stop()
		_music_b.volume_db = target_db
	else:
		_music_tween = create_tween().set_parallel(true)
		_music_tween.tween_property(_music_a, "volume_db", -40.0, fade_secs)
		_music_tween.tween_property(_music_b, "volume_db", target_db, fade_secs)
		_music_tween.chain().tween_callback(_music_a.stop)
	var old := _music_a
	_music_a = _music_b
	_music_b = old


func stop_music(fade_secs: float = 1.0) -> void:
	if current_music_key.is_empty() and not _music_a.playing:
		return
	current_music_key = ""
	if _music_tween != null and _music_tween.is_valid():
		_music_tween.kill()
	if fade_secs <= 0.05:
		_music_a.stop()
		_music_b.stop()
		return
	_music_tween = create_tween().set_parallel(true)
	_music_tween.tween_property(_music_a, "volume_db", -40.0, fade_secs)
	_music_tween.tween_property(_music_b, "volume_db", -40.0, fade_secs)
	_music_tween.chain().tween_callback(func():
		_music_a.stop()
		_music_b.stop()
	)


func play_stinger(key: String, volume_db: float = -4.0) -> void:
	var path: String = str(MUSIC_PATHS.get(key, ""))
	var stream := _get_stream(path, false)
	if stream == null:
		return
	_stinger.stream = stream
	_stinger.volume_db = volume_db
	_stinger.play()


func set_ambient_state(
	biome_track: String,
	weather_track: String,
	weather_gain: float,
	fire_gain: float,
	sanity_gain: float,
	delta: float
) -> void:
	var step := clampf(delta * 2.5, 0.0, 1.0)
	if biome_track != _current_biome_track:
		_switch_biome_ambient(biome_track)

	if weather_track.is_empty() or weather_gain <= 0.01:
		_lerp_loop(_amb_weather, "", 0.0, step)
		if not _amb_weather.playing:
			_current_weather_track = ""
	else:
		if weather_track != _current_weather_track or not _amb_weather.playing:
			_current_weather_track = weather_track
		_lerp_loop(_amb_weather, str(AMBIENT_PATHS.get(weather_track, "")), weather_gain, step)

	_lerp_loop(_amb_fire, str(AMBIENT_PATHS.get("campfire", "")), fire_gain, step)
	_lerp_loop(_amb_sanity, str(AMBIENT_PATHS.get("sanity_loop", "")), sanity_gain, step)


func _switch_biome_ambient(biome_track: String) -> void:
	_current_biome_track = biome_track
	if biome_track.is_empty():
		if _amb_biome_tween != null and _amb_biome_tween.is_valid():
			_amb_biome_tween.kill()
		_amb_biome_a.stop()
		_amb_biome_b.stop()
		return
	var stream := _get_stream(str(AMBIENT_PATHS.get(biome_track, "")), true)
	if stream == null:
		return
	if _amb_biome_tween != null and _amb_biome_tween.is_valid():
		_amb_biome_tween.kill()
	_amb_biome_b.stream = stream
	_amb_biome_b.volume_db = -40.0
	_amb_biome_b.play()
	_amb_biome_tween = create_tween().set_parallel(true)
	_amb_biome_tween.tween_property(_amb_biome_a, "volume_db", -40.0, 1.8)
	_amb_biome_tween.tween_property(_amb_biome_b, "volume_db", -10.0, 1.8)
	_amb_biome_tween.chain().tween_callback(_amb_biome_a.stop)
	var old := _amb_biome_a
	_amb_biome_a = _amb_biome_b
	_amb_biome_b = old


func _lerp_loop(player: AudioStreamPlayer, path: String, target_gain: float, step: float) -> void:
	var clamped := clampf(target_gain, 0.0, 1.0)
	if clamped > 0.01 and not path.is_empty():
		var stream := _get_stream(path, true)
		if stream != null and player.stream != stream:
			player.stream = stream
			player.volume_linear = 0.01
		if stream != null and not player.playing:
			player.play()
		player.volume_linear = lerpf(player.volume_linear, clamped, step)
	else:
		if player.playing:
			var next_lin := lerpf(player.volume_linear, 0.0, step)
			if next_lin <= 0.01:
				player.stop()
				player.volume_linear = 0.0
			else:
				player.volume_linear = next_lin


func stop_ambient() -> void:
	_current_biome_track = ""
	_current_weather_track = ""
	if _amb_biome_tween != null and _amb_biome_tween.is_valid():
		_amb_biome_tween.kill()
	for player in [_amb_biome_a, _amb_biome_b, _amb_weather, _amb_fire, _amb_sanity]:
		if player != null:
			player.stop()
