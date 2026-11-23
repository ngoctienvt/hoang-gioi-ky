# Giai đoạn 04: Yêu thú các biome

- **Trạng thái:** Chưa làm
- **Phụ thuộc:** 02 (hang trong set piece), 03 (pha theo mùa, Đông cho gấu ngủ đông)
- **Tiêu chí liên quan:** 1, 9, 10, 12

## Bối cảnh

GDD mục 4 (cột "Yêu thú & tập tính"), 6.1 tầng 4. Hiện AI là một chuỗi `if creature.kind == ...` trong `world_creatures.gd` (71 dòng, 3 loài). Thêm 10+ loài theo kiểu này sẽ vượt 200 dòng và khó test.

## Yêu cầu

1. **Tập tính tách file:** thêm `behavior: StringName` vào `CreatureDef`, kèm `params: Dictionary` (bán kính bầy, tầm đuổi, tốc chạy trốn...). Mỗi tập tính một file trong `world/simulation/behaviors/` có hàm tĩnh `tick(world, creature, definition, ctx, delta)`. `world_creatures.gd` chỉ còn: hồi quần thể, tìm người chơi gần nhất (qua chunk, không quét hết), gọi tập tính, di chuyển.
2. **Khung dùng chung:** trạng thái `idle`, `wander`, `flee`, `chase`, `attack`, `return`, `sleep`, `special`. Đòn đánh qua `world.hurt` như hiện tại. Yêu thú cũng nhận hiệu ứng `burn`, `slow`, `stun` (giai đoạn 05 tôi vũ khí dùng tới) — thêm khung hiệu ứng chung `effects: {name: thời gian}` ở đây.
3. **AI chỉ chạy gần người chơi:** yêu thú ở chunk ngoài bán kính 3 chunk của mọi người chơi đứng yên (không tick), chỉ hồi quần thể. Giữ băng thông và CPU trong ngưỡng.
4. **Ít nhất 2 loài mỗi biome** (bảng dưới), mỗi loài một `CreatureDef` `.tres` có đồ rơi. Thêm nguyên liệu rơi vào `data/items/`, trong đó có **Yêu Đan** các bậc (Sơ/Trung/Cao) để giai đoạn 07 và 08 dùng.
5. **Tương tác giữa loài** (nguyên tắc 3 của GDD), tối thiểu: quạ ăn xác (bay tới đồ rơi loại thịt và ăn mất), băng lang săn thú lông dày, sói đuổi thỏ.
6. **Lưu:** trường `effects`, `behavior_state` của yêu thú. `SAVE_VERSION` 5.

## Nội dung tối thiểu

| Biome | Loài | Tập tính (file) | Rơi |
|---|---|---|---|
| Rừng | Thỏ linh, Sói, Khỉ linh (đã có) | `herd_flee`, `pack_hunter`, `thief` | đã có |
| Rừng | Trĩ rừng | `herd_flee` (bầy, bay ngắn khi bị đuổi) | thịt nhỏ, lông vũ |
| Đầm Lầy | Đỉa linh | `leech` (bám người, hút Khí Huyết theo thời gian tới khi bị đánh) | Tinh Huyết sơ |
| Đầm Lầy | Quạ ăn xác | `scavenger` (ăn đồ rơi loại thịt, bay đi khi bị lại gần) | lông quạ |
| Đầm Lầy | Cương Thi / U Linh | `grave_rise` (trồi từ mộ cổ khi chạng vạng và đêm, đi chậm, về mộ lúc sáng; U Linh chỉ thấy khi Đạo Tâm thấp hoặc có Phá Hồn) | Âm Hồn Tinh, Yêu Đan sơ |
| Hỏa Sơn | Thằn lằn nham | `fire_defender` (hiền, bị đánh thì phun lửa vùng quanh, gây bỏng) | vảy nham, Yêu Đan sơ |
| Hỏa Sơn | Chim lửa | `nest_guard` (giữ tổ trên vách, lao xuống khi người lại gần tổ trứng) | lông lửa, trứng dị điểu |
| Lôi Trì | Linh thú Lôi | `pair_striker` (đi theo cặp, lướt nhanh rồi lùi) | lông Lôi, Yêu Đan trung |
| Lôi Trì | Thạch khôi lỗi | `dormant_golem` (ngủ cạnh trụ đá, tỉnh khi bị đánh hoặc sét đánh gần, rất chậm, rất trâu) | Lõi Cổ Khôi |
| Tuyết Lĩnh | Băng lang | `pack_hunter` (đàn 3–4, săn cả ngày) | da băng lang, Yêu Đan trung |
| Tuyết Lĩnh | Gấu tuyết | `hibernator` (ngủ; tỉnh khi bị đánh hoặc tiếng động lớn: sét, nổ, đánh nhau trong 8 m) | thịt lớn, lông dày |
| Tuyết Lĩnh | Thú lông dày | `herd_flee` | lông dày, thịt |
| Di Tích | Cơ quan thú | `patrol` (tuần tra quanh bệ đá theo vòng cố định, đuổi khi thấy) | bánh răng cổ, Tinh Thể Cổ Văn |
| Di Tích | Linh thể canh di tích | `night_guardian` (chỉ hiện đêm, xuyên công trình, sợ Đèn Dẫn Hồn) | Linh thể tinh, Yêu Đan cao |

Dơi hang, thú gặm nhấm (Lôi Trì) và cá/cua đầm, cá dưới băng là nguồn thức ăn dạng node (câu/bắt), làm ở 02 nếu kịp, nếu không làm ở đây dưới dạng `herd_flee` nhỏ.

## Các bước

1. Thêm `behavior`, `params` vào `CreatureDef`; chuyển 3 loài cũ sang file tập tính, test cũ phải vẫn qua.
2. Khung hiệu ứng `effects` và tìm người chơi theo chunk.
3. Viết từng file tập tính + `.tres` loài + vật phẩm rơi + khóa dịch.
4. Thêm hang/mộ/tổ/trụ vào set piece của từng biome.
5. Dạng khối nhìn khác nhau cho từng loài trong `entity_meshes.gd` (màu và tỉ lệ khối, mắt sáng theo GDD 1.1).
6. Chạy lại test băng thông với đủ yêu thú.

## Kiểm chứng

- Một file test cho mỗi nhóm tập tính (`tests/test_behavior_<tên>.gd`) dựng thế giới nhỏ có 1 người chơi và 1–2 con, kiểm tra chuyển trạng thái chính: đỉa bám và hút máu; gấu không tỉnh khi đi ngang, tỉnh khi bị đánh hoặc sét gần; cơ quan thú đi đúng vòng; Cương Thi chỉ trồi lúc tối; thằn lằn chỉ phun lửa khi bị đánh; quạ ăn thịt rơi.
- `tests/test_creature_population.gd`: mọi biome có ít nhất 2 loài sống sau khi sinh thế giới; yêu thú ngoài vùng người chơi không tick.

## Rủi ro

- Nhiều yêu thú đổi vị trí → patch lớn. Đã tách kênh vị trí ở 01; thêm ngưỡng chỉ gửi khi dịch hơn 0,2 m.

## Hoàn tác

Tập tính là file độc lập; tắt một loài bằng cách gỡ khỏi set piece.
