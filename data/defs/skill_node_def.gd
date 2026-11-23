## Định nghĩa một nút trên cây kỹ năng nhánh loại trừ của nhân vật. File .tres trong data/skills/.
class_name SkillNodeDef
extends Resource

@export var id: StringName = &""
@export var tree_id: StringName = &""
@export_range(1, 3) var tier: int = 1
@export var branch: StringName = &""
@export var excludes: Array[StringName] = []
@export var name_key: String = ""
@export var desc_key: String = ""
@export var effect_id: StringName = &""
@export var params: Dictionary = {}
