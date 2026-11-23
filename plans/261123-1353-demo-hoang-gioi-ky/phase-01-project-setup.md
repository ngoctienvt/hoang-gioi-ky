# Giai đoạn 01 — Cài đặt & khung dự án

**Trạng thái:** Xong (2026-11-23). GUT 9.7.1, test mẫu `tests/test_item_def.gd` qua headless. Cảnh thử: `world/style_test/style_test.tscn`, ảnh chụp ở `plans/reports/style-test-261123-1411-canh-thu-phong-cach.png`.

## Mục tiêu
Có project Godot chạy được, cấu trúc thư mục rõ ràng, khung autoload, hệ dịch tiếng Việt, framework test và git.

## Việc cần làm
1. **Godot 4.7.2 bản .NET** (plugin Godot-MCP chỉ biên dịch được trên bản .NET). Máy đã có .NET SDK 10, Node 24 và `godot-cli` 0.42.0. MCP cũ (`godot-mcp` qua npx) đã gỡ.
2. Tạo project tại `E:\TuTien` bằng `godot-cli create-project --dotnet --name "Hoang Gioi Ky"`, renderer **Forward+**.
3. Cài plugin và nối MCP: `godot-cli install-plugin .`, mở editor ở chế độ Custom (server local, có token), rồi `godot-cli setup-mcp claude-code . --url http://localhost:<port> --token <token>`. Token không ghi vào git.
3. Cấu trúc thư mục:
   ```
   autoload/        # network_manager, game_clock, item_db, recipe_db, save_manager, event_bus
   components/      # health, inventory, interactable, workable, durability
   data/items/      # ItemDef .tres
   data/recipes/    # RecipeDef .tres
   data/nodes/      # ResourceNodeDef .tres
   data/creatures/
   entities/player/ entities/creatures/ entities/resource_nodes/ entities/structures/ entities/ground_item/
   world/           # sinh bản đồ, set piece
   ui/              # HUD, kho đồ, menu chế tác, Thiên Thư
   shaders/         # shader tô màu kiểu tranh vẽ, hiệu ứng viền mực Tâm Ma
   localization/    # vi.csv (sau thêm en)
   tests/           # GUT
   ```
4. Định nghĩa các lớp Resource gốc: `ItemDef`, `RecipeDef`, `ResourceNodeDef`, `CreatureDef` (chỉ khung trường dữ liệu).
5. Autoload rỗng có chú thích vai trò. `EventBus` chứa các signal toàn cục.
6. Hệ dịch: `localization/strings.csv` với cột `keys,vi`. Mọi chữ hiển thị dùng `tr("KEY")`.
7. Cài **GUT** vào `addons/gut`. Viết 1 test mẫu và chạy headless:
   `godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`
8. **Cảnh thử phong cách** theo GDD mục 1.1: một cây tán tròn, một tảng đá, một cổng cổ phong dựng bằng khối đơn giản, tô màu phẳng ấm. Bật `WorldEnvironment` với sương theo khoảng cách, bloom nhẹ, trời chạng vạng cam đỏ, và camera phối cảnh nghiêng. Mục đích là chốt cảm giác hình ảnh sớm, trước khi làm gameplay.
9. `git init`, thêm `.gitignore` cho Godot (`.godot/`, `*.import` giữ lại, export bỏ qua).
10. Cập nhật `README.md` (mô tả ngắn, cách chạy, cách chạy test).

## Hoàn thành khi
- Mở project không lỗi. Cảnh thử phong cách cho cảm giác gần ảnh tham chiếu (màu ấm, sương, bloom, kiến trúc cổ phong).
- Test mẫu GUT chạy headless và qua.
- Có commit đầu tiên.

## Rủi ro
- Plugin GUT phải đúng phiên bản cho Godot 4.6. Đã dùng GUT 9.7.1, chạy được trên Godot 4.7.2.
