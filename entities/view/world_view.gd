extends Node3D

const Shapes = preload("res://entities/view/entity_meshes.gd")
const WorldSeason = preload("res://world/simulation/world_season.gd")
const BoundaryDao = preload("res://world/simulation/traits/boundary_dao.gd")
var visuals: Dictionary = {}
var targets: Array = []
var desired: Dictionary = {}
var sun: DirectionalLight3D
var environment: Environment
var latest_state: Dictionary = {}
var local_peer := 1
var audio: Node
var local_prediction := Vector3.INF
var style = preload("res://entities/view/world_style.gd").new()
var built_seed := -1
var ground_root: Node3D
var weather_particles: CPUParticles3D
var warning_root: Node3D
var ink_overlay: ColorRect
var karma_cloud: MeshInstance3D


func _ready() -> void:
	audio = preload("res://entities/view/world_audio.gd").new()
	add_child(audio)
	var art: Dictionary = style.install(self)
	sun = art.sun
	environment = art.environment
	ink_overlay = art.get("ink_overlay")
	_apply_graphics_settings()
	SettingsManager.settings_changed.connect(_apply_graphics_settings)
	ground_root = Node3D.new()
	add_child(ground_root)
	warning_root = Node3D.new()
	add_child(warning_root)
	karma_cloud = MeshInstance3D.new()
	var cm := SphereMesh.new()
	cm.radial_segments = 10
	cm.rings = 5
	karma_cloud.mesh = cm
	karma_cloud.visible = false
	var cmat := StandardMaterial3D.new()
	cmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cmat.albedo_color = Color(0.95, 0.88, 0.55, 0.35)
	karma_cloud.material_override = cmat
	add_child(karma_cloud)
	weather_particles = CPUParticles3D.new()
	weather_particles.amount = 140
	weather_particles.lifetime = 0.8
	weather_particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	weather_particles.emission_box_extents = Vector3(14.0, 0.5, 14.0)
	weather_particles.direction = Vector3(0.0, -1.0, 0.0)
	weather_particles.spread = 8.0
	weather_particles.initial_velocity_min = 12.0
	weather_particles.initial_velocity_max = 18.0
	var pmesh := BoxMesh.new()
	pmesh.size = Vector3(0.04, 0.35, 0.04)
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.75, 0.85, 0.95, 0.7)
	pmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pmesh.material = pmat
	weather_particles.mesh = pmesh
	weather_particles.emitting = false
	add_child(weather_particles)


func _build_ground(state: Dictionary) -> void:
	var seed_val := int(state.get("seed", 0))
	if seed_val == built_seed:
		return
	for child in ground_root.get_children():
		child.queue_free()
	var regions: Array = state.get("regions", [])
	var map_size := float(state.get("options", {}).get("map_size", 80.0))
	var half := map_size * 0.5
	for i in 4:
		var edge := BoxMesh.new()
		edge.size = Vector3(map_size, 1, 0.6) if i < 2 else Vector3(0.6, 1, map_size)
		Shapes.mesh(ground_root, edge, Color("77715a"), [Vector3(0, 0.1, -half), Vector3(0, 0.1, half), Vector3(-half, 0.1, 0), Vector3(half, 0.1, 0)][i])
	if regions.size() >= 6:
		var centers: PackedVector2Array = PackedVector2Array()
		var colors: PackedVector3Array = PackedVector3Array()
		var accents: PackedVector3Array = PackedVector3Array()
		for i in 6:
			var region: Dictionary = regions[i]
			var c: Array = region.center
			centers.append(Vector2(float(c[0]), float(c[2])))
			var bpath := "res://data/biomes/%s.tres" % str(region.get("biome", "bamboo_forest"))
			var bdef: BiomeDef = load(bpath) if ResourceLoader.exists(bpath) else null
			var gcol := bdef.ground_color if bdef != null else Color("3f523a")
			var acol := bdef.accent_color if bdef != null else Color("6fa05a")
			colors.append(Vector3(gcol.r, gcol.g, gcol.b))
			accents.append(Vector3(acol.r, acol.g, acol.b))
		var plane := PlaneMesh.new()
		plane.size = Vector2(map_size, map_size)
		var mat := ShaderMaterial.new()
		mat.shader = preload("res://shaders/biome_ground.gdshader")
		mat.set_shader_parameter("biome_centers", centers)
		mat.set_shader_parameter("biome_colors", colors)
		mat.set_shader_parameter("biome_accents", accents)
		mat.set_shader_parameter("warp_phase", float(regions[0].get("warp_phase", 0.0)))
		mat.set_shader_parameter("blend_width", 12.0)
		var ground_mesh := MeshInstance3D.new()
		ground_mesh.mesh = plane
		ground_mesh.material_override = mat
		ground_mesh.position = Vector3(0, 0.0, 0)
		ground_root.add_child(ground_mesh)
	built_seed = seed_val


func _apply_graphics_settings() -> void:
	if sun != null:
		sun.shadow_enabled = SettingsManager.shadows
	if environment != null:
		environment.fog_enabled = SettingsManager.fog

func render(state: Dictionary, local_id: int) -> void:
	latest_state = state
	local_peer = local_id
	if state.is_empty():
		built_seed = -1
		for child in ground_root.get_children():
			child.queue_free()
	else:
		_build_ground(state)
	targets.clear()
	var present := {}
	var local: Dictionary = state.get("players", {}).get(str(local_id), {})
	var sensing := float(local.get("sense_time", 0)) > 0
	var dao_val := float(local.get("stats", {}).get("dao", 100.0))
	var fx: Dictionary = local.get("effects", {})
	var can_see_hidden := dao_val < 30.0 or sensing or fx.has("spirit_sight") or fx.has("pierce_mist") or BoundaryDao.in_boundary(local)
	if ink_overlay != null and ink_overlay.material is ShaderMaterial:
		var ink_int := clampf((40.0 - dao_val) / 35.0, 0.0, 1.0)
		if BoundaryDao.outside_boundary(local):
			ink_int = maxf(ink_int, 0.75)
		ink_overlay.material.set_shader_parameter("intensity", ink_int)
	_update_karma_cloud(state)
	for category in ["players", "nodes", "drops", "structures", "creatures", "puppets", "npcs"]:
		var entities: Array = []
		if category == "players":
			for id in state.get("players", {}):
				var player: Dictionary = state.players[id].duplicate(true)
				player.uid = int(id)
				player.kind = "player"
				entities.append(player)
		else: entities = state.get(category, [])
		for entity in entities:
			entity.collection = category
			var key: String = category + str(entity.uid)
			present[key] = true
			if category == "players" and visuals.has(key):
				var prev_char := str(visuals[key].get_meta("character", ""))
				var cur_char := str(entity.get("character", ""))
				if prev_char != cur_char:
					visuals[key].queue_free()
					visuals.erase(key)
			if not visuals.has(key):
				var visual := Shapes.create(String(entity.get("kind", "")), category, entity)
				visual = style.decorate(visual, String(entity.get("kind", "")), category)
				add_child(visual)
				visuals[key] = visual
				visual.position = _position(entity.get("position", [0, 0, 0]))
				if category == "players":
					visual.set_meta("character", str(entity.get("character", "")))
					var name_label := Label3D.new()
					name_label.name = "PlayerName"
					name_label.text = entity.get("name", "")
					name_label.position.y = 2
					name_label.font_size = 30
					name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
					visual.add_child(name_label)
			var visual: Node3D = visuals[key]
			desired[key] = _position(entity.get("position", [0, 0, 0]))
			if category == "players" and int(entity.uid) == local_id and local_prediction.is_finite(): desired[key] = local_prediction
			visual.visible = not (category == "nodes" and float(entity.get("regrow", 0)) > 0)
			if str(entity.get("kind", "")) in ["floor_trap", "wraith", "phantom"]:
				visual.visible = visual.visible and can_see_hidden
			if category == "creatures":
				var cstate := str(entity.get("state", ""))
				var ckind := str(entity.get("kind", ""))
				visual.visible = visual.visible and cstate != "dead" and not (cstate in ["sleep", "burrow"] and ckind in ["rabbit", "spirit_rabbit", "jiangshi", "ruin_wraith"])
			if category == "nodes": visual.scale = Vector3.ONE * (0.35 if int(entity.get("stage", 0)) > 0 else 1.0)
			if category == "players":
				visual.scale = Vector3.ONE * (1.45 if float(entity.get("beast", entity.get("beast_time", 0))) > 0 else 1.0)
				_set_ghost(visual, entity.get("ghost", false), float(entity.get("hit_flash", 0)) > 0)
				var hand: Dictionary = entity.get("inventory", {}).get("equipment", {}).get("hand", {})
				_fire(visual, hand.get("id", "") == "torch")
			_highlight(visual, sensing and category in ["nodes", "creatures"] and _position(entity.position).distance_to(_position(local.get("position", [0, 0, 0]))) < 16)
			if "fire" in String(entity.kind): _fire(visual, float(entity.get("fuel", 0)) > 0)
			if category != "players" or int(entity.uid) != local_id:
				targets.append(entity)
	for key in visuals.keys():
		if not present.has(key):
			visuals[key].queue_free()
			visuals.erase(key)
			desired.erase(key)
	var clock: Dictionary = state.get("clock", {})
	var phase := str(clock.get("phase", "day"))
	var season_def := WorldSeason.get_def(str(clock.get("season", "autumn")))
	var base_tint := season_def.sky_tint if season_def != null else Color(0.88, 0.76, 0.6)
	if sun:
		sun.light_energy = 0.95 if phase == "day" else 0.5 if phase == "dusk" else 0.025
		sun.light_color = base_tint if phase == "day" else Color("c58b68") if phase == "dusk" else Color("788aba")
		environment.ambient_light_energy = 0.85 if phase == "day" else 0.3 if phase == "dusk" else 0.06
	if weather_particles:
		var wkind := str(state.get("weather", {}).get("kind", "clear"))
		weather_particles.emitting = wkind in ["rain", "snow", "storm"]
		var lp := _position(local.get("position", [0.0, 0.0, 0.0]))
		weather_particles.position = Vector3(lp.x, 12.0, lp.z)
		weather_particles.initial_velocity_min = 4.0 if wkind == "snow" else 14.0
		weather_particles.initial_velocity_max = 6.0 if wkind == "snow" else 20.0
	if warning_root:
		for child in warning_root.get_children():
			child.queue_free()
		for w in state.get("weather", {}).get("warnings", []):
			if w is Dictionary:
				Shapes.cylinder(warning_root, Color(0.55, 0.9, 1.0, 0.55), _position(w.get("position", [0, 0, 0])) + Vector3(0, 0.05, 0), 1.6, 0.06)

func _process(delta: float) -> void:
	if audio and not latest_state.is_empty(): audio.update(latest_state, local_peer, delta)
	for key in visuals:
		visuals[key].position = visuals[key].position.lerp(desired[key], minf(1, delta * 14))

func get_target(world_position: Vector3) -> Dictionary:
	var best: Dictionary = {}
	var distance := 1.7
	for entity in targets:
		if float(entity.get("regrow", 0)) > 0 or entity.get("state", "") == "dead": continue
		if str(entity.get("kind", "")) in ["ruin_path", "mud"]: continue
		var next := _position(entity.position).distance_to(world_position)
		if next < distance:
			distance = next
			best = entity
	return best

func _position(value: Array) -> Vector3:
	return Vector3(value[0], value[1], value[2])

func _set_ghost(node: Node3D, ghost: bool, hit: bool) -> void:
	for child in node.get_children():
		if child is MeshInstance3D:
			var material := child.material_override as StandardMaterial3D
			if not child.has_meta("base_color"): child.set_meta("base_color", material.albedo_color)
			material.albedo_color = Color("ff574c") if hit else Color("9de8e2") if ghost else child.get_meta("base_color")
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if ghost else BaseMaterial3D.TRANSPARENCY_DISABLED
			material.albedo_color.a = 0.35 if ghost else 1.0

func _fire(node: Node3D, burning: bool) -> void:
	var light := node.get_node_or_null("FireLight") as OmniLight3D
	if not light:
		light = OmniLight3D.new()
		light.name = "FireLight"
		light.position.y = 1
		light.light_color = Color("ffb259")
		light.omni_range = 8
		light.light_energy = 2.5
		node.add_child(light)
	light.visible = burning

func _highlight(node: Node3D, active: bool) -> void:
	for child in node.get_children():
		if child is MeshInstance3D:
			var material := child.material_override as StandardMaterial3D
			if material:
				material.emission_enabled = active
				material.emission = Color("6be7ca")
				material.emission_energy_multiplier = 0.65
			elif child.material_override is ShaderMaterial:
				child.material_override.set_shader_parameter("shade_floor", 0.95 if active else 0.28)
		_highlight(child, active) if child is Node3D else null


func _update_karma_cloud(state: Dictionary) -> void:
	if karma_cloud == null:
		return
	var structures: Array = state.get("structures", [])
	var karma: Dictionary = state.get("karma", {})
	var sin_v := float(karma.get("sin", 0.0))
	var fate_v := float(karma.get("fate", 0.0))
	var diff := absf(fate_v - sin_v)
	if structures.is_empty() or diff < 5.0:
		karma_cloud.visible = false
		return
	var avg := Vector3.ZERO
	for s in structures:
		avg += _position(s.position)
	avg /= float(structures.size())
	karma_cloud.visible = true
	karma_cloud.position = Vector3(avg.x, 7.5, avg.z)
	var thickness := clampf(diff / 100.0, 0.15, 0.85)
	karma_cloud.scale = Vector3(4.5 + thickness * 4.0, 1.0 + thickness, 4.5 + thickness * 4.0)
	var mat := karma_cloud.material_override as StandardMaterial3D
	if mat != null:
		mat.albedo_color = Color(0.98, 0.9, 0.55, thickness * 0.65) if fate_v >= sin_v else Color(0.12, 0.1, 0.14, thickness * 0.75)

