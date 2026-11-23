## Định nghĩa một nhân vật Dị Nhân. File .tres trong data/characters/.
class_name CharacterDef
extends Resource

@export var id: StringName = &""
@export var name_key: String = ""
@export var desc_key: String = ""
@export var power_key: String = ""
@export var cost_key: String = ""
@export var max_health: float = 150.0
@export var move_speed: float = 5.0
@export var heal_rate: float = 1.0
@export var unarmed_damage_mult: float = 1.0
@export var poison_threshold: float = 100.0
@export var abilities: Array[AbilityDef] = []
@export var trait_id: StringName = &""
@export var skill_tree_id: StringName = &""
@export var tribulation_id: StringName = &""
@export var body_color: Color = Color("a74f3f")
@export var selectable: bool = true
