# Giai đoạn 01: Nền móng (mạng theo thay đổi, vùng quan tâm, file lưu có phiên bản)

- **Trạng thái:** Chưa làm
- **Phụ thuộc:** không
- **Tiêu chí liên quan:** 9, 10, 12

## Bối cảnh

Code hiện tại đúng kiến trúc host quyết định, nhưng có các điểm sẽ vỡ khi thế giới lớn gấp nhiều lần:

| Chỗ | Vấn đề |
|---|---|
| `world/demo_session.gd::_publish` | Mỗi 0,1 giây chụp `snapshot()` (sao chép sâu cả thế giới), so sánh sâu từng nhóm và gửi lại **cả nhóm** qua kênh reliable khi một phần tử đổi |
| `DemoWorld.find_any` | Nối mảng `nodes + drops + structures + creatures` mỗi lần tra uid, O(n) và tạo mảng mới |
| `world_creatures.move` | Kẹp tọa độ cứng `±39` |
| `world_seed.gd` | 4 vùng đặt cứng, bản đồ 80×80 m |
| `SaveManager.load_world` | Từ chối mọi file có `version != 1`, không có chuyển đổi |
| `DemoWorld.step` | Khí Huyết tối đa `150` ghi cứng; danh sách khóa cooldown ghi cứng ở hai nơi (`add_player`, `world_life.step`) |
| `demo_session.gd` 199 dòng, `demo_ui.gd` 194, `demo_main.gd` 190 | Không thêm được gì nếu không tách |

## Yêu cầu

1. **Đổi tên** `demo_*` thành tên hệ thống thật (bảng dưới). Cập nhật `project.godot` (main scene), test và README.
2. **Chỉ mục thực thể:** `world.index: Dictionary uid -> entity` cập nhật khi thêm/xóa. `find_any` tra chỉ mục. Mọi chỗ thêm/xóa thực thể đi qua `world.add_entity(collection, e)` / `world.remove_entity(e)`.
3. **Chia vùng (chunk):** lưới 24 m. `world.chunks: Dictionary "cx,cz" -> Array[uid]`. Thực thể di chuyển (yêu thú, người chơi) đổi chunk khi qua biên. Kích thước bản đồ đọc từ `state.options.map_size` thay cho hằng `±39`.
4. **Đồng bộ theo thay đổi từng thực thể:**
   - Mọi thay đổi trạng thái thực thể đi qua `world.touch(uid)` (đánh dấu bẩn). Hàm tiện ích sửa trường (`world.set_field(e, key, value)`) gọi `touch` tự động; code cũ sửa trực tiếp Dictionary phải được rà và thêm `touch`.
   - Mỗi tick mạng (10 Hz), session tạo **patch riêng cho từng peer**: `{"upsert": [entity...], "remove": [uid...], "players": ..., "clock": ...}` chỉ gồm thực thể bẩn nằm trong vùng quan tâm của peer đó.
   - **Vùng quan tâm:** các chunk trong bán kính 2 chunk (khoảng 60 m) quanh người chơi. Khi peer vào chunk mới, gửi toàn bộ thực thể của chunk đó; khi rời quá bán kính 3 chunk, gửi `remove` để client bỏ.
   - Vị trí yêu thú gửi qua kênh `unreliable_ordered` riêng (`[uid, x, z]` gói gọn), tối đa 10 Hz; trạng thái khác qua kênh reliable.
   - Client giữ bản sao cục bộ `uid -> entity`, áp patch, phát `state_received` như cũ để UI và view không phải viết lại một lần.
   - Không còn `snapshot()` mỗi tick. `snapshot()` chỉ dùng khi lưu và khi peer mới vào.
5. **File lưu có phiên bản:** `SAVE_VERSION = 2`. `SaveManager` có chuỗi chuyển đổi `_migrate(data, from_version)` chạy từng bước 1→2→… Bản 1 (demo) chuyển được sang 2 (thêm `options.map_size`, chỉ mục dựng lại khi `restore`). File có phiên bản lớn hơn bản game thì báo lỗi, không mở.
6. **Khóa cooldown và chỉ số nền** gom về một bảng dữ liệu (`world_rules.gd` hoặc `.tres` nhân vật mặc định) để giai đoạn sau thêm nhân vật không phải sửa nhiều nơi.
7. **Bài test băng thông** (tiêu chí 10, xem mục Kiểm chứng).

## Bảng đổi tên

| Cũ | Mới |
|---|---|
| `world/demo.tscn`, `world/demo_main.gd` | `world/game.tscn`, `world/game_main.gd` (+ tách `world/game_main_scene_setup.gd`) |
| `world/demo_session.gd` | `world/session/game_session.gd` (đăng ký, intent), `world/session/state_replicator.gd` (patch theo peer), `world/session/interest_grid.gd` (vùng quan tâm) |
| `world/demo_controls.gd` | `world/player_controls.gd` |
| `world/simulation/demo_world.gd` (`DemoWorld`) | `world/simulation/game_world.gd` (`GameWorld`) + `world/simulation/world_entity_index.gd` |
| `entities/demo/*` | `entities/view/*` (`world_view.gd`, `entity_meshes.gd`, `world_style.gd`, `world_audio.gd`, `network_avatar.gd`) |
| `ui/demo/*` | `ui/hud/*` (`game_ui.gd` tách thành `game_ui.gd` + `hud_panels.gd`), `ui/menu/main_menu.gd` |

Khóa dịch giữ nguyên tên nếu không có chữ `DEMO`; khóa có `DEMO` đổi tên và cập nhật `strings.csv`.

## Các bước

1. Đổi tên file bằng `git mv`, sửa `preload`, `class_name`, main scene. Chạy GUT ngay (phải vẫn 28/28) trước khi đổi logic.
2. Thêm chỉ mục uid và `add_entity`/`remove_entity`; thay mọi `state.x.append/erase` trong `world/simulation/`.
3. Thêm lưới chunk và `map_size`; bỏ kẹp `±39`.
4. Thêm `touch`/dirty set; rà từng file `world/simulation/*.gd` để mọi chỗ sửa thực thể đều đánh dấu bẩn (test: chạy một ngày mô phỏng, so `snapshot()` phía host với bản client dựng từ patch, phải bằng nhau).
5. Viết `state_replicator.gd` và `interest_grid.gd`; đổi `receive_state` thành `receive_patch` + `receive_positions`.
6. Viết chuyển đổi file lưu 1→2.
7. Viết test băng thông và test đồng nhất host/client.
8. Chạy GUT, main scene headless, `tools/test-network.ps1`. Commit.

## Kiểm chứng

- `tests/test_entity_index.gd`: thêm/xóa/tra uid; chỉ mục dựng lại đúng sau `restore`.
- `tests/test_state_replication.gd`: mô phỏng host với 4 peer giả (không mạng), áp patch vào 4 bản client; sau 600 tick, thực thể trong vùng quan tâm của mỗi client trùng với host; thực thể ngoài vùng không có ở client.
- `tests/test_save_migration.gd`: file bản 1 mẫu (đặt trong `tests/fixtures/`) nạp được thành bản 2; file bản 99 bị từ chối.
- `tests/test_bandwidth.gd`: thế giới giả **5.000 thực thể** (trong đó 300 yêu thú di chuyển), 4 người chơi đứng ở 4 góc, mô phỏng 60 giây ở 10 Hz. Cộng `var_to_bytes(patch).size()` cho từng peer. **Ngưỡng qua:** trung bình mỗi peer ≤ 48 KB/s phía tải xuống, gói lớn nhất ≤ 64 KB, gói vào chunk mới ≤ 256 KB. In số đo ra log để ghi vào báo cáo.
- `tools/test-network.ps1` mở rộng thành tùy chọn `-Clients 3` (host + 3 client) và in thống kê byte gửi/nhận của ENet (`ENetPacketPeer.get_statistic`). Đây là bài kiểm chứng thật, bài GUT ở trên là bài đo logic.

## Rủi ro

- Bỏ sót một chỗ sửa thực thể mà không `touch` → client lệch. Giảm bằng test đồng nhất ở bước 4 và một chế độ debug so khớp toàn thế giới mỗi 10 giây (chỉ bật trong test).
- Đổi tên hàng loạt làm hỏng scene `.tscn` (đường dẫn script). Chạy main scene headless ngay sau bước 1.

## Hoàn tác

Mỗi bước là thay đổi độc lập trên cùng nhánh; nếu replicator mới hỏng, giữ cờ `options.legacy_sync` tạm thời trong lúc làm, xóa trước khi commit.

## Ràng buộc nhắc lại

File code dưới 200 dòng. Không ghi tên plan hay số giai đoạn vào code, tên test, commit. Mọi chữ hiển thị qua `tr()`.
