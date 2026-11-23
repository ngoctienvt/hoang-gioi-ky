extends CharacterBody3D
## Only the server moves collision bodies. Local prediction is visual, never authority.
var peer_id := 1
var direction := Vector2.ZERO
var speed := 5.0
var ghost := false
var input_age := 0.0
var authoritative_position := Vector3.ZERO
var map_limit := 39.0
var in_secret_realm := false

func _ready() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.5
	shape.shape = capsule
	shape.position.y = 0.75
	add_child(shape)
	var sync := MultiplayerSynchronizer.new()
	sync.name = "State"
	var config := SceneReplicationConfig.new()
	config.add_property(^".:authoritative_position")
	config.property_set_replication_mode(^".:authoritative_position", SceneReplicationConfig.REPLICATION_MODE_ALWAYS)
	sync.replication_config = config
	sync.replication_interval = 0.05
	add_child(sync)

func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	input_age += delta
	if input_age > 0.4:
		direction = Vector2.ZERO
	velocity = Vector3(direction.x, 0, direction.y) * speed
	move_and_slide()
	if in_secret_realm:
		position.x = clampf(position.x, 1200.0 - 16.0, 1200.0 + 16.0)
		position.z = clampf(position.z, 1200.0 - 16.0, 1200.0 + 16.0)
	else:
		position.x = clampf(position.x, -map_limit, map_limit)
		position.z = clampf(position.z, -map_limit, map_limit)
	position.y = 0.0
	authoritative_position = position
