# Hoang Giới Ký

Game sinh tồn co-op 1–4 người, bối cảnh huyền huyễn, làm bằng Godot 4.7.2 (.NET), code game bằng GDScript.

- Thiết kế: [docs/game-design-document.md](docs/game-design-document.md)
- Kế hoạch demo: [plans/261123-1353-demo-hoang-gioi-ky/plan.md](plans/261123-1353-demo-hoang-gioi-ky/plan.md)
- Kế hoạch asset 3D (Hunyuan3D-Omni): [plans/261123-1413-3d-asset-pipeline-hunyuan3d-omni/plan.md](plans/261123-1413-3d-asset-pipeline-hunyuan3d-omni/plan.md)

## Yêu cầu

- Godot 4.7.2 **bản .NET**: `D:\Downloads\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64\`
- .NET SDK 10, Node.js 22.14+
- `godot-cli` (Godot-MCP): `npm install -g godot-cli`

## Chạy game

Main scene: `res://world/demo.tscn`. Demo dùng lại cảnh phong cách `world/style_test/style_test.tscn` qua `entities/demo/demo_style.gd`.

```powershell
& "D:/Downloads/Godot_v4.7.2-stable_mono_win64/Godot_v4.7.2-stable_mono_win64/Godot_v4.7.2-stable_mono_win64_console.exe" --path .
```

Hoặc mở project trong editor rồi bấm F5.

### Điều khiển demo

- **WASD** di chuyển; con lăn zoom; chuột trái nhặt/khai thác/đánh/chọn mục tiêu.
- **Tab** mở chế tác; **B** mở Thiên Thư; **Space** thao tác với tài nguyên gần.
- **Q** Hóa Thú; **F** Thú Giác; chuột phải theo mục tiêu để nướng, múc nước, thu hoạch hoặc tương tác nồi/lò/hồi sinh.
- Chọn ô đồ để dùng trong tương tác; chuột phải ô đồ để ăn/trang bị, kéo thả đổi ô, CTRL kéo để tách, Shift click thả. **Esc**/chuột phải hủy đặt công trình.

### Chơi cùng và lưu thế giới

Host tạo thế giới; tối đa **4 người**, mỗi người dùng tên riêng. Client nhập IP máy host; cùng máy dùng `127.0.0.1`. Cho phép Godot qua firewall với **UDP 24565**. Qua Internet, host cần chuyển tiếp UDP 24565 trên router tới máy host và dùng IP công khai; mạng CGNAT có thể không nhận kết nối trực tiếp.

Host bấm Lưu hoặc rời game để lưu; game cũng tự lưu đầu ngày. Chọn thế giới đã lưu ở menu, vào lại bằng **đúng tên cũ** để nhận nhân vật trước đó. File lưu: `user://saves/`; log lỗi/thao tác: `user://logs/game.log` (Windows thường ở `%APPDATA%/Godot/app_userdata/Hoang Giới Ký/`). Slot lưu không đọc được sẽ báo lỗi thay vì tạo thế giới mới đè lên.

Phần mã demo đã triển khai; chờ chủ dự án chơi thử theo [báo cáo triển khai](plans/reports/implementation-261123-1425-demo.md). Chưa có bản Windows xuất và chưa xác nhận LAN 10 ngày. Theo yêu cầu hiện tại, AI không chạy thêm game/test/biên dịch; các lệnh dưới đây dành cho chủ dự án khi cần.


## Chạy test

Test dùng [GUT](https://github.com/bitwes/Gut) 9.7.1 (`addons/gut`), file test đặt trong `tests/` với tiền tố `test_`.

```powershell
& "D:/Downloads/Godot_v4.7.2-stable_mono_win64/Godot_v4.7.2-stable_mono_win64/Godot_v4.7.2-stable_mono_win64_console.exe" --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Exit code 0 là qua hết, 1 là có test hỏng. Trên checkout mới, chạy `--headless --path . --import` một lần trước để Godot nhận các `class_name`.

Kiểm tra lỗi script và C# của toàn project (cần đặt `GODOT_BIN` trỏ tới file `_console.exe` ở trên):

```powershell
godot-cli check --allow-open .
```

## Cấu trúc thư mục

| Thư mục | Nội dung |
|---|---|
| `autoload/` | Singleton toàn cục: `EventBus`, `NetworkManager`, `GameClock`, `ItemDB`, `RecipeDB`, `SaveManager` |
| `components/` | Logic kho đồ và chỉ số sinh tồn; các trách nhiệm gameplay khác ở `world/simulation/` |
| `data/defs/` | Lớp Resource gốc: `ItemDef`, `RecipeDef`, `ResourceNodeDef`, `CreatureDef`... |
| `data/items`, `recipes`, `cooking`, `alchemy`, `nodes`, `creatures` | Dữ liệu `.tres` |
| `entities/` | Người chơi, yêu thú, điểm tài nguyên, công trình, đồ dưới đất |
| `world/` | Bản đồ, set piece, cảnh thử phong cách |
| `ui/` | HUD, kho đồ, menu chế tác, Thiên Thư |
| `shaders/` | Shader tô màu kiểu tranh vẽ |
| `localization/` | `strings.csv` (cột `keys,vi`). Mọi chữ hiển thị dùng `tr("KEY")` |
| `tests/` | Test GUT |

## Godot-MCP cho Claude Code

Plugin nằm ở `addons/godot_mcp`. Server MCP chạy local tại `http://localhost:26589`, có token bảo vệ.
Token nằm trong `.ai-game-dev/local-token`, cấu hình Claude Code nằm trong `.mcp.json`. Cả hai đều không đưa lên git.

Mở editor headless kèm server MCP (chạy lại sau mỗi lần khởi động máy):

```powershell
$env:GODOT_MCP_TOKEN = Get-Content .ai-game-dev\local-token -Raw
godot-cli open --headless --editor-path "D:/Downloads/Godot_v4.7.2-stable_mono_win64/Godot_v4.7.2-stable_mono_win64/Godot_v4.7.2-stable_mono_win64_console.exe" --mode Custom --auth Required --idle-timeout 0 .
```

Mở editor có giao diện để tự làm: chạy `Godot_v4.7.2-stable_mono_win64.exe` rồi mở thư mục này.
