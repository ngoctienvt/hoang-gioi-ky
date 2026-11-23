# Giai đoạn 03 — Vật phẩm, công cụ, thức ăn, đan

## Mục tiêu

Làm mục 4, 5, 6 của [asset-catalog.md](asset-catalog.md): nguyên liệu, công cụ, vũ khí, đồ mặc, thức ăn và đan dược.

## Lưu ý riêng cho nhóm này

1. **Một model dùng cho ba việc:** nằm dưới đất, cầm trên tay nhân vật (công cụ, vũ khí, đuốc) và render icon 2D. Vì vậy model phải nhận ra ngay khi nhìn nghiêng 3/4 từ trên xuống, ở cỡ nhỏ.
2. **Phóng đại hình bóng.** Vật phẩm nhỏ thì phóng đại phần đặc trưng: lưỡi rìu to hơn thật, quả to hơn thật, tinh thể Linh Thạch góc cạnh rõ. Kích thước trong catalog đã tính phóng đại.
3. **Pivot:**
   - Nguyên liệu, thức ăn, đan: tâm đáy, nằm vững trên mặt đất (không lăn, không lơ lửng).
   - **Công cụ và vũ khí cầm tay** (`tool_*`, `weapon_spear`): pivot ở **điểm tay nắm** (khoảng 1/4 từ đuôi cán). Cán dọc theo trục **+Y** (đầu rìu, đầu cuốc, mũi giáo hướng lên +Y). Lưỡi rìu và lưỡi cuốc hướng về **-Y của Blender** (mặt trước). Thêm một empty tên `ground_pivot` ở chỗ vật nằm chạm đất khi thả xuống (Godot dùng empty này để đặt đồ dưới đất).
4. **Công cụ thời tiền sử thô sơ:** đá buộc dây vào cán gỗ, thấy rõ dây buộc. Không có kim loại ở demo (trừ Lò Đan và đồ quý).
5. **Đan dược dùng chung một mesh** `pill_base` (viên tròn hơi dẹt, đường kính 0,05 m, khoảng 150 tam giác, phóng to 1,5 lần cho dễ thấy). Xuất 5 file, mỗi file một texture màu khác nhau theo catalog. Có thể đặt viên đan trong lọ sứ nhỏ nếu làm icon đẹp hơn, nhưng cả 5 dùng chung lọ.
6. **Thức ăn nấu bằng nồi** dùng chung 2–3 kiểu bát, đĩa (bát gốm, bát to, đĩa lá). Làm bát trước, rồi chỉ thay phần thức ăn bên trong.
7. **Giáp cỏ (`armor_grass`):**
   - `armor_grass_item.glb`: gấp lại, nằm đất.
   - `armor_grass_worn.glb`: làm sau khi đã có rig nhân vật (phase-05). Áo choàng cỏ mặc lên thân, skin vào cùng bộ xương nhân vật, xuất riêng một GLB chỉ có mesh giáp + bộ xương.
8. **Bình Đựng Nước:** `empty` và `filled` chung mesh, `filled` thêm dải vải buộc nút màu linh khí `#9FE8C8`.
9. **Đuốc:** đầu đuốc quấn vải, có empty `flame_socket` ở chỗ lửa cháy. Godot gắn hạt lửa và đèn vào đó.
10. **Nhiều món nhỏ dựng tay nhanh hơn dùng Omni** (đá lửa, viên đan, răng sói, dây thừng). Chỉ dùng Omni khi có lợi.

## Mẫu prompt concept (phần [MÔ TẢ VẬT THỂ])

- Rìu đá: `a primitive stone axe, a chipped grey stone head tied with straw rope onto a short wooden handle, game item`
- Cuốc đá: `a primitive stone pickaxe, a pointed grey stone head tied with rope onto a wooden handle, game item`
- Giáo: `a long primitive wooden spear with a sharpened flint tip tied with rope, game item`
- Canh Linh Quả: `a rustic clay bowl of warm orange fruit soup with floating berries and herbs, game food item`
- Linh Thạch: `a single cyan spiritual crystal chunk with faceted edges, game item`

## Việc cần làm

1. Làm 21 nguyên liệu P0 trước (rất nhiều món nhỏ, làm theo lô 7 món một lần, cùng bảng màu).
2. Làm 8 công cụ, vũ khí, đồ mặc P0 (trừ `armor_grass_worn` chờ rig).
3. Làm 13 thức ăn, đan P0.
4. Đặt tất cả lên một mặt phẳng, chụp từ góc camera game để kiểm tra độ dễ nhận ra. Chụp thêm từng món ở cỡ 64×64 px (giả lập icon) để kiểm tra.
5. PR `assets/items-batch-1`, `assets/items-batch-2`...

## Hoàn thành khi

- Mọi id P0 trong mục 4–6 qua checklist phase-06.
- Ở cỡ 64×64 px, người không biết trước vẫn gọi đúng tên ít nhất 9/10 món (thử với chủ dự án).

## Rủi ro

- Các món na ná nhau (đá, đá lửa, Linh Thạch; thịt nhỏ và thịt): khác nhau rõ về hình và màu. Đá lửa có cạnh sắc màu tối, đá tròn xám, Linh Thạch xanh ngọc phát sáng.
