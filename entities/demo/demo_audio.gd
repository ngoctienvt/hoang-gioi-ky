extends Node

var last_event := ""
var warning_timer := 0.0
var effect: AudioStreamPlayer

func _ready() -> void:
	effect = AudioStreamPlayer.new()
	effect.volume_db = -16
	add_child(effect)

func update(state: Dictionary, peer: int, delta: float) -> void:
	var events: Array = state.get("events", [])
	if not events.is_empty():
		var event: Dictionary = events.back()
		var signature := str(event)
		if signature != last_event and event.get("event", "") == "action":
			var verb := String(event.get("details", {}).get("verb", ""))
			_tone(420 if verb == "pickup" else 130 if verb == "work" else 85 if verb == "attack" else 260, 0.11, verb in ["work", "attack"])
		last_event = signature
	warning_timer -= delta
	var player: Dictionary = state.get("players", {}).get(str(peer), {})
	if float(player.get("darkness", 0)) > 1 and warning_timer <= 0:
		_tone(62, 0.35, true)
		warning_timer = 1.3

func _tone(frequency: float, duration: float, noise: bool) -> void:
	var bytes := PackedByteArray()
	var count := int(22050 * duration)
	bytes.resize(count * 2)
	for i in count:
		var envelope := pow(1.0 - float(i) / count, 2)
		var sample := sin(TAU * frequency * i / 22050)
		if noise: sample = sample * 0.5 + randf_range(-0.5, 0.5)
		bytes.encode_s16(i * 2, int(sample * envelope * 20000))
	var wave := AudioStreamWAV.new()
	wave.format = AudioStreamWAV.FORMAT_16_BITS
	wave.mix_rate = 22050
	wave.data = bytes
	effect.stream = wave
	effect.play()
