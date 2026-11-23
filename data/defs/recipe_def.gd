## Công thức chế tác (Bàn Chế Tác, chế tay). File .tres trong data/recipes/.
## Công thức nồi và lò đan dùng hệ thẻ riêng, không dùng lớp này.
class_name RecipeDef
extends Resource

enum Group { TOOLS, LIGHT, SURVIVAL, COMBAT, STRUCTURES, TALISMANS, PUPPETS }

@export var id: StringName = &""
## Vật phẩm tạo ra.
@export var result: ItemDef
@export_range(1, 99) var result_count: int = 1
## Nguyên liệu: ItemDef.id -> số lượng cần.
@export var ingredients: Dictionary[StringName, int] = {}
## 0 = tay không, 1 = phải đứng gần Bàn Chế Tác.
@export_range(0, 5) var tier: int = 0
@export var group: Group = Group.TOOLS
## Công trình bắt buộc đứng gần (tùy chọn, ví dụ &"talisman_desk", &"refining_forge").
@export var station: StringName = &""
## Tỉ lệ thành công (bùa chú). Thất bại thì chỉ mất giấy bùa, không ra sản phẩm.
@export_range(0.0, 1.0) var success: float = 1.0
## true = công thức cấm, chỉ chế được khi đã mở khóa.
@export var forbidden_unlock: bool = false
## true = sản phẩm là công trình đặt xuống đất (lửa trại, bàn chế tác...).
@export var is_structure: bool = false
