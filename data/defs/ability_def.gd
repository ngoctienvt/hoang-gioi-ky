## Định nghĩa một chiêu thức của nhân vật. File .tres trong data/abilities/.
class_name AbilityDef
extends Resource

@export var id: StringName = &""
@export var name_key: String = ""
@export var desc_key: String = ""
@export var cooldown: float = 0.0
## "", "stamina", "poison", "dao", "health", "item"
@export var cost_type: String = ""
@export var cost_amount: float = 0.0
@export var cost_item: StringName = &""
@export var forbidden: bool = false
@export var sin_amount: float = 4.0
@export var effect: StringName = &""
