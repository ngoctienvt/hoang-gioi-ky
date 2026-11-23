# Giai đoạn 05 — Nhân vật & yêu thú (rig, hoạt ảnh)

## Mục tiêu

Làm mục 8 của [asset-catalog.md](asset-catalog.md): nhân vật Huyết Mạch Cổ Thú (và dạng Hóa Thú), thỏ linh, sói rừng, khỉ linh, có rig và đủ hoạt ảnh. Đây là phần khó và tốn thời gian nhất, nên bắt đầu sớm.

## Lưu ý riêng cho nhóm này

### Hình khối

1. **Tỉ lệ cách điệu:** đầu hơi to (khoảng 1/6 chiều cao thay vì 1/7,5), tay chân khối rõ, bàn tay đơn giản (ngón cái + khối 4 ngón là đủ). Nhìn từ trên xuống vẫn phân biệt được đầu, vai, tay.
2. **Nhân vật dùng khống chế `pose`** của Omni với tư thế **A-pose** (tay xòe xuống khoảng 45 độ, chân hơi dạng). Kết hợp `bbox` cao 1,7 m.
3. **Yêu thú:** ảnh concept nhìn ngang hoặc 3/4, đứng thẳng 4 chân, miệng ngậm, đuôi duỗi. Dùng `bbox` theo kích thước catalog.
4. **Mesh Omni thường không đủ tốt để rig.** Sau khi Omni ra hình, phải **retopo** (dựng lại lưới) bằng Quad Remesher, Instant Meshes hoặc Remesh + chỉnh tay, có vòng cạnh (edge loop) quanh khớp vai, khuỷu, gối, hông, cổ. Bake màu từ mesh Omni (đã tô Paint) sang mesh retopo.
5. **Texture 1024** (sói, nhân vật) hoặc **512** (thỏ, khỉ), tô kiểu tranh vẽ phẳng, chuyển sắc mềm, mắt to rõ.

### Rig

| Model | Cách rig khuyên dùng |
|---|---|
| Nhân vật | AccuRig (miễn phí, chạy local) hoặc Mixamo (cần mạng, chỉ cho người) hoặc Rigify. Bộ xương chuẩn humanoid để Godot retarget được |
| Hóa Thú | Cùng bộ xương nhân vật, chỉ đổi mesh. Nếu tỉ lệ khác quá nhiều thì rig riêng |
| Thỏ, sói | Rigify mẫu "Quadruped" hoặc tự dựng xương: hông, 3–4 đốt sống, cổ, đầu, hàm, 4 chân (mỗi chân 3–4 xương), đuôi 3–4 đốt, tai 2 đốt (thỏ) |
| Khỉ | Rigify humanoid sửa thêm đuôi 4–5 đốt |

- Bộ xương không quá **60 xương** (nhân vật) và **40 xương** (thú). Không có xương phụ điều khiển (control bone) trong file xuất; chỉ xuất xương biến dạng (deform bones).
- Tên xương nhân vật theo chuẩn humanoid (Hips, Spine, Chest, Neck, Head, LeftUpperArm...), để Godot dùng `SkeletonProfileHumanoid` retarget.
- Thêm xương hoặc empty **`hand_r_socket`** ở lòng bàn tay phải (cầm công cụ) và **`head_socket`** trên đỉnh đầu (đồ đội đầu sau này). Hướng của `hand_r_socket`: trục +Y dọc theo hướng cán công cụ khi nắm, để khớp pivot công cụ ở phase-03.

### Hoạt ảnh

- 30 fps. Tên clip đúng như catalog, viết thường. Clip lặp (`idle`, `walk`, `run`, `hop`, `sleep`, `carry`) phải khớp khung đầu và khung cuối.
- **Hoạt ảnh tại chỗ (in-place):** không di chuyển gốc nhân vật về phía trước, Godot tự di chuyển.
- Độ dài gợi ý: `idle` 2–3 giây, `walk` 1 giây, `run` 0,7 giây, `attack`, `chop`, `mine`, `dig` khoảng 0,6–0,8 giây (có khoảnh khắc trúng ở khoảng 40% clip, ghi lại khung trúng vào manifest để Godot khớp hiệu ứng), `hit` 0,3 giây, `death` 1–1,5 giây và giữ tư thế cuối.
- Động tác phóng đại, rõ ràng kiểu game DST: lấy đà trước đòn, dừng ngắn sau đòn.
- Nhân vật người có thể lấy hoạt ảnh nền từ thư viện (Mixamo...) rồi chỉnh lại cho phóng đại hơn. Ghi rõ nguồn hoạt ảnh vào manifest.
- `beast_transform`: khoảng 1,5 giây, nhân vật cúi gập, gồng người. Godot sẽ đổi mesh sang dạng Hóa Thú ở cuối clip.

### Hướng và pivot

- Mặt trước quay về -Y trong Blender (+Z sau khi xuất).
- Pivot ở tâm đáy, giữa hai bàn chân (thú: giữa 4 chân), đúng mặt đất ở tư thế `idle`.

## Việc cần làm

1. `creature_forest_wolf`: hoàn thiện từ mẫu đã duyệt ở phase-01 → retopo → rig → hoạt ảnh. Làm sói trước vì dùng làm mẫu cho các thú 4 chân khác.
2. `char_ancient_beast_blood`: concept A-pose → Omni (`pose` + `bbox`) → retopo → texture → rig → hoạt ảnh → socket.
3. `creature_spirit_rabbit`, `creature_spirit_monkey`.
4. `armor_grass_worn` (từ phase-03) skin vào rig nhân vật.
5. P1: `char_ancient_beast_blood_beastform`.
6. Với mỗi model: xuất GLB có cả mesh, xương và mọi clip; mở lại GLB trong Blender hoặc Godot để kiểm tra từng clip chạy đúng.
7. PR `assets/characters-batch-1`, `assets/creatures-batch-1`.

## Hoàn thành khi

- 4 model P0 có rig và đủ clip bắt buộc theo catalog, qua checklist phase-06.
- Trong Godot, mở GLB thấy đủ clip trong AnimationPlayer, phát từng clip không méo lưới ở khớp.
- Công cụ gắn vào `hand_r_socket` cầm đúng tay, đúng hướng.

## Rủi ro

- Hoạt ảnh thú 4 chân tự làm tốn nhiều công nhất. Nếu chậm, giao trước bản có `idle`, `walk`, `run`, `attack`, `death` để phía game làm AI trước, các clip còn lại giao sau.
- Retopo kém thì méo lưới khi gập khớp: thử tư thế gập mạnh nhất (ngồi xổm, vung tay qua đầu) trước khi làm hoạt ảnh.
