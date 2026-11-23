## Định nghĩa một loại vật phẩm. Mỗi vật phẩm là một file .tres trong data/items/.
## Chỉ chứa dữ liệu, không chứa logic. Logic kho đồ nằm ở components/.
class_name ItemDef
extends Resource

enum Category { MATERIAL, TOOL, WEAPON, FOOD, ELIXIR, STRUCTURE }
enum ToolType { NONE, AXE, PICKAXE, SHOVEL }

## Mã định danh duy nhất, ví dụ "twig", "flint_axe".
@export var id: StringName = &""
## Khóa dịch tên hiển thị, dùng với tr().
@export var name_key: String = ""
## Khóa dịch mô tả.
@export var desc_key: String = ""
@export var icon: Texture2D
@export var category: Category = Category.MATERIAL
@export_range(1, 999) var max_stack: int = 99

@export_group("Công cụ & vũ khí")
@export var tool_type: ToolType = ToolType.NONE
@export_range(1, 5) var tool_tier: int = 1
## 0 = không có độ bền (không hỏng).
@export_range(0, 9999) var max_durability: int = 0
@export_range(0.0, 999.0) var damage: float = 0.0
@export var equipment_slot: StringName = &""
@export var insulation: float = 0.0
@export var cooling: float = 0.0
@export_range(0.0, 1.0) var waterproof: float = 0.0

@export_group("Thức ăn")
## Lượng hồi khi ăn, có thể âm (đồ sống trừ Đạo Tâm).
@export var restore_stamina: float = 0.0
@export var restore_health: float = 0.0
@export var restore_dao_heart: float = 0.0
## Thời gian hư hỏng (giây), 0 = không hỏng.
@export_range(0.0, 100000.0) var spoil_time: float = 0.0
@export var warm_effect: float = 0.0
@export var cool_effect: float = 0.0

@export_group("Thẻ nấu & luyện đan")
## Thẻ thuộc tính kèm giá trị, ví dụ { &"fruit": 1.0, &"meat": 0.5 }.
## Nồi Linh Thực và Lò Đan dùng tổng thẻ để khớp công thức.
@export var tags: Dictionary[StringName, float] = {}
## Hiệu ứng khi dùng: { "effect_name": [magnitude, duration] }.
@export var effects: Dictionary = {}
## Hiệu ứng bùa khi ném/dùng: "bind", "frost", "true_sight", "ghost_mask", "lightning_ward".
@export var talisman_effect: StringName = &""


func is_stackable() -> bool:
	return max_stack > 1


func get_tag(tag: StringName) -> float:
	return tags.get(tag, 0.0)
