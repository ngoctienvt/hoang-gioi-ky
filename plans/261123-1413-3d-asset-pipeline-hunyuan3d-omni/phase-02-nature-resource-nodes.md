# Giai đoạn 02 — Cây, đá, bụi: điểm tài nguyên & trang trí

## Mục tiêu

Làm toàn bộ mục 1, 2, 3 của [asset-catalog.md](asset-catalog.md): cây, trúc, đá, bụi, Linh Thảo, Thanh Mộc Tuyền, đồ trang trí và hang ổ yêu thú. Đây là phần chiếm nhiều diện tích màn hình nhất, nên quyết định cảm giác của cả game.

## Lưu ý riêng cho nhóm này

1. **Các giai đoạn của cùng một điểm tài nguyên phải khớp nhau.** Ví dụ `rock_boulder_stage1/2/3` và `tree_common_a_standing/stump`:
   - Làm `stage1` (hoặc `standing`) trước, duyệt xong mới làm giai đoạn sau.
   - Giai đoạn sau làm **từ chính mesh giai đoạn trước trong Blender** (cắt bớt, đập vỡ bằng Boolean hoặc Cell Fracture, rồi giảm poly), **không** tạo lại bằng Omni. Như vậy chỗ đặt, màu và hướng vân sẽ khớp, khi đổi giai đoạn người chơi không thấy nhảy hình.
   - Gốc cây (`stump`) đặt đúng vị trí và cùng đường kính với chân thân cây ở `standing`.
2. **Cây đổ** do Godot làm (xoay mesh `standing` đổ xuống rồi biến mất). Vì vậy pivot cây ở tâm đáy thân cây, không phải tâm tán.
3. **Tán lá:** khối tròn to, 3–6 cụm, không làm từng lá. Mặt trên sáng (`#808C47`), mặt dưới tối (`#4E5B32`). Với cách tô bảng màu, gán UV mặt trên vào ô sáng, mặt dưới vào ô tối, phần giữa chuyển sắc.
4. **Biến thể cây** (`tree_common_a/b/c`): cùng chiều cao và bảng màu, khác dáng tán và độ nghiêng thân. Dùng khống chế `bbox` giống nhau cho cả ba, đổi ảnh concept.
5. **Linh Thạch:** tinh thể là object con tên `crystal`, gán vào ô màu `#5FD3E0`. Godot sẽ thêm phát sáng cho object này.
6. **Bụi linh quả:** quả là object con tên `berries`. Giai đoạn `picked` chỉ cần xóa object `berries`, không làm lại bụi.
7. **Búi cỏ trang trí (`decor_grass_tuft`):** giới hạn **80 tam giác** vì Godot rải hàng nghìn cái bằng MultiMesh. Làm bằng tay trong Blender (vài tấm lá chéo nhau) nhanh hơn dùng Omni. Không cần Omni cho nhóm trang trí nhỏ nếu dựng tay nhanh hơn.
8. **Thanh Mộc Tuyền:** chỉ làm vòng đá, rêu, cây nhỏ xung quanh. Chỗ mặt nước để trống, là một vùng phẳng hình tròn hoặc bầu dục ở độ cao 0,1 m, Godot đặt mặt nước có shader vào đó. Thêm một empty tên `water_surface` đặt ở tâm mặt nước.
9. **Hang ổ:** để trống chỗ yêu thú chui ra vào. Ổ khỉ cần một mặt phẳng tên `loot_spot` (empty) làm chỗ đặt đồ trộm.

## Mẫu prompt concept (phần [MÔ TẢ VẬT THỂ])

- Cây gỗ thường: `a sturdy deciduous tree with a thick slightly curved brown trunk and three big round chunky clumps of dark green foliage`
- Linh trúc: `a cluster of seven tall jade-green bamboo stalks with small leaf tufts at the top, glowing faint spiritual aura`
- Tảng đá: `a large rounded boulder with soft beveled edges, blue-grey stone, small moss patches on top`
- Tảng Linh Thạch: `a large boulder with several cyan glowing crystals growing out of its cracks`
- Bụi linh quả: `a round leafy bush covered with clusters of small glossy orange-red berries`
- Thanh Mộc Tuyền: `a small natural spring pool surrounded by a ring of mossy stones, ferns and tiny plants, empty center`

## Việc cần làm

1. Làm theo thứ tự ưu tiên P0 trong catalog: `tree_common_a` (đã có từ phase-01) → `bamboo_cluster` → `rock_boulder` → `rock_spirit_ore` → `bush_berry` → `bush_grass` → `bush_twig` → `herb_spirit_wild` → `spring_thanh_moc` → `decor_grass_tuft` → 3 hang ổ.
2. Với mỗi id: làm giai đoạn đầu bằng quy trình chuẩn (phase-01), làm các giai đoạn sau từ mesh đó, kiểm tra (phase-06), ghi manifest.
3. Gom thành PR `assets/nature-batch-1` (P0), rồi `assets/nature-batch-2` (P1).

## Hoàn thành khi

- Mọi id P0 trong mục 1–3 có đủ file theo giai đoạn, qua checklist phase-06.
- Ảnh contact sheet: đặt hết cạnh hình nhân 1,7 m, nhìn từ góc camera game, các cây đá đồng bộ màu và tỉ lệ.

## Rủi ro

- Omni ra tán lá lởm chởm nhiều mảnh nhỏ: dùng Remesh (Voxel) rồi Decimate để ra khối tròn mềm, hoặc dựng lại tán bằng vài khối icosphere biến dạng.
- Cây quá cao che mất nhân vật dưới góc camera: giữ chiều cao 5–6 m như catalog, không cao hơn.
