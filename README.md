# Hoang Giới Ký

Game sinh tồn co-op 1–4 người, bối cảnh huyền huyễn, làm bằng Godot 4.7.2 (.NET), code game bằng GDScript.

- Thiết kế: [docs/game-design-document.md](docs/game-design-document.md)
- Kế hoạch demo: [plans/261123-1353-demo-hoang-gioi-ky/plan.md](plans/261123-1353-demo-hoang-gioi-ky/plan.md)

## Yêu cầu

- Godot 4.7.2 **bản .NET**: `D:\Downloads\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64\`
- .NET SDK 10, Node.js 22.14+
- `godot-cli` (Godot-MCP): `npm install -g godot-cli`

## Chạy game

Main scene hiện là cảnh thử phong cách `res://world/style_test/style_test.tscn`.

```powershell
& "D:/Downloads/Godot_v4.7.2-stable_mono_win64/Godot_v4.7.2-stable_mono_win64/Godot_v4.7.2-stable_mono_win64_console.exe" --path .
```

Hoặc mở project trong editor rồi bấm F5.

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
| `components/` | Component tái dùng (máu, kho đồ, tương tác, khai thác, độ bền) |
| `data/defs/` | Lớp Resource gốc: `ItemDef`, `RecipeDef`, `ResourceNodeDef`, `CreatureDef`... |
| `data/items`, `recipes`, `nodes`, `creatures` | Dữ liệu `.tres` |
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
