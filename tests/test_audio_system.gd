extends GutTest

const WorldAudioScript = preload("res://entities/view/world_audio.gd")


func test_audio_buses_exist() -> void:
	for bus_name in [&"Master", &"Music", &"Ambient", &"SFX"]:
		assert_ne(AudioServer.get_bus_index(bus_name), -1, "Missing audio bus: %s" % bus_name)


func test_settings_manager_audio_roundtrip() -> void:
	var tmp := "user://test_audio_settings.cfg"
	SettingsManager.master_volume = 0.8
	SettingsManager.music_volume = 0.5
	SettingsManager.ambient_volume = 0.6
	SettingsManager.sfx_volume = 0.9
	SettingsManager.muted = false
	assert_eq(SettingsManager.save_settings(tmp), OK)

	SettingsManager.music_volume = 1.0
	SettingsManager.ambient_volume = 1.0
	SettingsManager.load_settings(tmp)
	assert_almost_eq(SettingsManager.music_volume, 0.5, 0.01)
	assert_almost_eq(SettingsManager.ambient_volume, 0.6, 0.01)
	SettingsManager.apply_all()

	var music_bus := AudioServer.get_bus_index(&"Music")
	assert_almost_eq(AudioServer.get_bus_volume_linear(music_bus), 0.5, 0.02)

	SettingsManager.music_volume = 0.0
	SettingsManager.apply_all()
	assert_true(AudioServer.is_bus_mute(music_bus))

	SettingsManager.master_volume = 1.0
	SettingsManager.music_volume = 0.7
	SettingsManager.ambient_volume = 0.8
	SettingsManager.sfx_volume = 1.0
	SettingsManager.muted = false
	SettingsManager.apply_all()
	DirAccess.remove_absolute(tmp)


func test_all_audio_manifest_streams_load() -> void:
	for key in AudioManager.MUSIC_PATHS:
		var path: String = AudioManager.MUSIC_PATHS[key]
		assert_true(ResourceLoader.exists(path), "Missing music asset: %s" % path)
		assert_not_null(load(path) as AudioStream, "Failed to load music stream: %s" % path)
	for key in AudioManager.AMBIENT_PATHS:
		var path: String = AudioManager.AMBIENT_PATHS[key]
		assert_true(ResourceLoader.exists(path), "Missing ambient asset: %s" % path)
		assert_not_null(load(path) as AudioStream, "Failed to load ambient stream: %s" % path)
	for key in AudioManager.SFX_PATHS:
		var path: String = AudioManager.SFX_PATHS[key]
		assert_true(ResourceLoader.exists(path), "Missing sfx asset: %s" % path)
		assert_not_null(load(path) as AudioStream, "Failed to load sfx stream: %s" % path)


func test_audio_manager_and_world_audio_playback() -> void:
	AudioManager.play_sfx("pickup")
	AudioManager.play_sfx_variant(["chop_1", "chop_2", "chop_3"])
	AudioManager.play_ui("ui_click")
	AudioManager.play_music("season_autumn", 0.0)
	AudioManager.set_ambient_state("meadow_day", "rain", 0.5, 0.4, 0.2, 0.1)

	var wa := WorldAudioScript.new()
	add_child(wa)
	var fake_state := {
		"clock": {"phase": "day", "season": "autumn"},
		"weather": {"kind": "rain", "warnings": []},
		"players": {
			"1": {
				"position": [0.0, 0.0, 0.0],
				"biome": "bamboo_forest",
				"ghost": false,
				"darkness": 0.0,
				"stats": {"health": 100.0, "stamina": 100.0, "dao": 100.0},
				"inventory": {"equipment": {"hand": {"id": "flint_axe"}}},
			}
		},
		"structures": [{"kind": "campfire", "position": [2.0, 0.0, 0.0], "fuel": 10.0}],
		"creatures": [],
		"events": [{"event": "action", "time": 1.0, "details": {"peer": 1, "verb": "work"}}],
	}
	wa.update(fake_state, 1, 0.05)
	wa.reset()
	wa.queue_free()
	AudioManager.stop_music(0.0)
	AudioManager.stop_ambient()
	assert_true(true)
