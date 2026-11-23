extends GutTest


func test_settings_manager_roundtrip_and_keybind_conflict_swap() -> void:
	var tmp := "user://test_settings.cfg"
	SettingsManager.master_volume = 0.65
	SettingsManager.sfx_volume = 0.45
	SettingsManager.muted = true
	SettingsManager.shadows = false
	SettingsManager.fog = false
	assert_eq(SettingsManager.save_settings(tmp), OK)

	SettingsManager.master_volume = 1.0
	SettingsManager.muted = false
	SettingsManager.shadows = true
	SettingsManager.load_settings(tmp)
	assert_almost_eq(SettingsManager.master_volume, 0.65, 0.01)
	assert_almost_eq(SettingsManager.sfx_volume, 0.45, 0.01)
	assert_true(SettingsManager.muted)
	assert_false(SettingsManager.shadows)
	assert_false(SettingsManager.fog)

	# Conflict swap: rebinding ability_1 to KEY_E (currently ability_2) swaps them
	SettingsManager.reset_bindings()
	var orig_ab1 := SettingsManager.key_for("ability_1")
	var orig_ab2 := SettingsManager.key_for("ability_2")
	assert_true(SettingsManager.rebind("ability_1", orig_ab2))
	assert_eq(SettingsManager.key_for("ability_1"), orig_ab2)
	assert_eq(SettingsManager.key_for("ability_2"), orig_ab1)
	SettingsManager.reset_bindings()
	SettingsManager.muted = false
	SettingsManager.shadows = true
	SettingsManager.fog = true
	SettingsManager.master_volume = 1.0
	SettingsManager.sfx_volume = 1.0
	SettingsManager.apply_all()
	DirAccess.remove_absolute(tmp)


func test_all_data_resources_have_vietnamese_translations() -> void:
	TranslationServer.set_locale("vi")
	var dirs := [
		"res://data/items/",
		"res://data/creatures/",
		"res://data/characters/",
		"res://data/abilities/",
		"res://data/skills/",
		"res://data/imprints/",
		"res://data/biomes/",
		"res://data/seasons/",
		"res://data/karma/",
	]
	var checked := 0
	for d in dirs:
		for file in ResourceLoader.list_directory(d):
			if not file.ends_with(".tres"):
				continue
			var res = load(d + file)
			if res == null:
				continue
			var nkey = res.get("name_key")
			if nkey != null and not str(nkey).is_empty():
				checked += 1
				var translated := TranslationServer.translate(str(nkey))
				assert_ne(translated, str(nkey), "Missing translation for %s in %s" % [str(nkey), d + file])
	assert_gt(checked, 80)
