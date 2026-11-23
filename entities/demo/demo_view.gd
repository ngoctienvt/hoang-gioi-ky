extends Node3D

const Shapes = preload("res://entities/demo/demo_meshes.gd")
var visuals: Dictionary = {}
var targets: Array = []
var desired: Dictionary = {}
var sun: DirectionalLight3D
var environment: Environment
var latest_state: Dictionary = {}
var local_peer := 1
var audio: Node
var local_prediction := Vector3.INF
var style = preload("res://entities/demo/demo_style.gd").new()

func _ready() -> void:
	audio = preload("res://entities/demo/demo_audio.gd").new()
	add_child(audio)
	var art: Dictionary = style.install(self)
	sun = art.sun
	environment = art.environment
	for i in 4:
		var edge := BoxMesh.new()
		edge.size = Vector3(80, 1, 0.6) if i < 2 else Vector3(0.6, 1, 80)
		Shapes.mesh(self, edge, Color("77715a"), [Vector3(0, 0.1, -40), Vector3(0, 0.1, 40), Vector3(-40, 0.1, 0), Vector3(40, 0.1, 0)][i])

func render(state: Dictionary, local_id: int) -> void:
	latest_state = state
	local_peer = local_id
	targets.clear()
	var present := {}
	var local: Dictionary = state.get("players", {}).get(str(local_id), {})
	var sensing := float(local.get("sense_time", 0)) > 0
	for category in ["players", "nodes", "drops", "structures", "creatures"]:
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
			if not visuals.has(key):
				var visual := Shapes.create(String(entity.get("kind", "")), category)
				visual = style.decorate(visual, String(entity.get("kind", "")), category)
				add_child(visual)
				visuals[key] = visual
				visual.position = _position(entity.get("position", [0, 0, 0]))
				if category == "players":
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
			if category == "creatures": visual.visible = entity.get("state", "") != "dead"
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
	var duration := maxf(1, float(state.get("options", {}).get("day_length", clock.get("day_length", 480))))
	var progress := fmod(float(clock.get("elapsed", 0)), duration) / duration
	var phase := "day" if progress < 0.5 else "dusk" if progress < 0.875 else "night"
	if sun:
		sun.light_energy = 0.95 if phase == "day" else 0.5 if phase == "dusk" else 0.025
		sun.light_color = Color(0.88, 0.76, 0.6) if phase == "day" else Color("c58b68") if phase == "dusk" else Color("788aba")
		environment.ambient_light_energy = 0.85 if phase == "day" else 0.3 if phase == "dusk" else 0.06

func _process(delta: float) -> void:
	if audio and not latest_state.is_empty(): audio.update(latest_state, local_peer, delta)
	for key in visuals:
		visuals[key].position = visuals[key].position.lerp(desired[key], minf(1, delta * 14))

func get_target(world_position: Vector3) -> Dictionary:
	var best: Dictionary = {}
	var distance := 1.7
	for entity in targets:
		if float(entity.get("regrow", 0)) > 0 or entity.get("state", "") == "dead": continue
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

