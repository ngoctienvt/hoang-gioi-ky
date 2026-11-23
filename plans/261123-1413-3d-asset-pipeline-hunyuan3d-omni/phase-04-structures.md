# Giai đoạn 04 — Công trình Sơn Môn

## Mục tiêu

Làm mục 7 của [asset-catalog.md](asset-catalog.md): Lửa Trại, Lò Lửa, Bàn Chế Tác, Rương, Nồi Linh Thực, Lò Đan, Ruộng Linh Thảo, Hồi Hồn Đài.

## Lưu ý riêng cho nhóm này

1. **Bộ phận chuyển động là object con riêng** có tên đúng như catalog (`lid`, `door`, `logs_full`, `logs_low`, `ash`, `crop_*`). Pivot của object con đặt ở đúng chỗ xoay: nắp rương ở bản lề sau, cửa lò ở bản lề bên. Không làm hoạt ảnh, Godot tự xoay.
2. **Empty "socket"** (ví dụ `flame_socket`, `steam_socket`, `smoke_socket`, `fire_socket`, `spirit_socket`) là chỗ Godot gắn hiệu ứng. Tạo bằng Add → Empty → Plain Axes, đặt đúng vị trí, đặt tên chính xác.
3. **Dùng greybox để khóa hình.** Công trình có hình dạng chức năng (bàn cao vừa tay, rương đủ to, đài có bậc) nên:
   - Dựng khối greybox trong Blender theo kích thước catalog, đặt cạnh hình nhân 1,7 m.
   - Xuất point cloud từ greybox, dùng khống chế `point` hoặc `voxel` của Omni cùng ảnh concept để ra mesh bám đúng khung.
4. **Phong cách theo bậc:** đồ bậc 0 (Lửa Trại, Bàn Chế Tác) thô sơ bằng đá, gỗ, dây. Đồ bậc 1 (Nồi, Lò Đan, Hồi Hồn Đài) bắt đầu có nét cổ phong: gốm men, đồng vàng `#C9A24A`, sơn đỏ `#A8322B`, mái cong nhỏ, hoa văn mây đơn giản.
5. **Đáy phẳng, pivot tâm đáy.** Công trình đặt trên mọi chỗ đất phẳng, nên đáy không có chân lơ lửng hay lún.
6. **Đọc được từ trên xuống.** Mặt trên của công trình là mặt người chơi thấy nhiều nhất: Lò Đan nhìn từ trên vẫn thấy rõ miệng lò, Ruộng thấy rõ luống cây, Hồi Hồn Đài thấy rõ vòng đài.
7. **Ruộng Linh Thảo:** 4 giai đoạn cây là object con chồng lên nhau trong cùng file (`crop_seed`, `crop_young`, `crop_grown`, `crop_mutated`). `crop_mutated` có quả to phát sáng màu linh khí.

## Mẫu prompt concept (phần [MÔ TẢ VẬT THỂ])

- Lửa trại: `a campfire made of a ring of rounded stones with stacked firewood logs in the middle, unlit`
- Bàn Chế Tác: `a rough handmade wooden crafting workbench with a stone axe, a coil of rope and wood planks on top`
- Lò Đan: `an ancient chinese bronze alchemy furnace on three legs with a small door, gold trim and cloud motifs`
- Hồi Hồn Đài: `a round stone altar platform with three steps, two red lacquered wooden pillars and an incense burner in the center`
- Nồi Linh Thực: `a glazed clay cooking pot with a lid standing on a tripod of stones above a fire pit`

## Việc cần làm

1. Thứ tự: `struct_campfire` (đã có từ phase-01) → `struct_crafting_table` → `struct_chest` → `struct_fire_pit` → `struct_cook_pot` → `struct_alchemy_furnace` → `struct_herb_field` → `struct_revive_altar`.
2. Với mỗi công trình: greybox → concept → Omni có khống chế → làm sạch → tách object con và đặt socket → texture → kiểm tra → manifest.
3. PR `assets/structures-batch-1`.

## Hoàn thành khi

- 8 công trình P0 qua checklist phase-06.
- Object con và socket đúng tên như catalog (phase-06 có bước kiểm tra tên).

## Rủi ro

- Omni gộp nắp và thân thành một khối liền: cắt nắp ra trong Blender, vá lỗ ở cả hai phần.
