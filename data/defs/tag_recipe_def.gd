class_name TagRecipeDef
extends Resource

@export var id: String = ""
@export var result: ItemDef
@export var minimum: Dictionary[StringName, float] = {}
@export var maximum: Dictionary[StringName, float] = {}
@export var forbidden: Array[StringName] = []
@export var priority: int = 0
@export var weight: float = 1.0
@export var time: float = 10.0
@export var success: float = 1.0
@export var solvent_tag: StringName = &""

func matches(tags: Dictionary) -> bool:
	for tag in minimum:
		if float(tags.get(tag, 0.0)) < minimum[tag]:
			return false
	for tag in maximum:
		if float(tags.get(tag, 0.0)) > maximum[tag]:
			return false
	for tag in forbidden:
		if float(tags.get(tag, 0.0)) > 0.0:
			return false
	return true
