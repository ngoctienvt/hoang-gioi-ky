# Giai đoạn 03: Mùa, nhiệt độ, thời tiết, hư hỏng thực phẩm

- **Trạng thái:** Chưa làm
- **Phụ thuộc:** 02 (biome tại vị trí, nước Xích Viêm và Huyền Băng)
- **Tiêu chí liên quan:** 2, 9, 12

## Bối cảnh

GDD 7.3, 7.4, 6.6 (bùa ẩm mùa Xuân). Hiện `game_world.step` chia pha cố định 0,5/0,875 của ngày, không có mùa. `GameClock` chỉ có ngày và thời gian trôi.

## Yêu cầu

1. **Mùa:** `SeasonDef` `.tres` (`data/seasons/`) cho Thu, Đông, Xuân, Hạ: độ dài ngày mặc định (20/15/20/15), số phần Ngày/Chạng vạng/Đêm trên 16 theo bảng GDD 7.4, nhiệt độ nền, xác suất mưa/tuyết. Độ dài mùa chỉnh được khi tạo thế giới (`options.season_lengths`). Thế giới bắt đầu mùa Thu.
2. **Pha trong ngày** tính từ bảng của mùa hiện tại (thay 0,5/0,875). `GameClock` có `season`, `season_day`, `days_to_next_season`. HUD hiện mùa và báo trước khi còn 3 ngày đổi mùa.
3. **Nhiệt độ cơ thể** (`stats.temperature`, 0–100, 50 là dễ chịu): mỗi giây tiến dần về **nhiệt độ môi trường** = nền mùa + bù biome (Hỏa Sơn +25, Tuyết Lĩnh −25) + nguồn nhiệt gần (lửa trại +, băng khối −) + đồ mặc + hiệu ứng (đan, nước Xích Viêm/Huyền Băng ngâm/uống, đồ ăn nóng/lạnh). Dưới 15: cóng, mất Khí Huyết. Trên 85: say nắng, mất Khí Huyết. Đông: giảm tốc ra đòn 20% khi lạnh dưới 30 ("ra chiêu chậm").
4. **Đồ mặc ô thân và ô đầu:** thêm ô `head` vào trang bị. Vật phẩm có `insulation` (giữ ấm) hoặc `cooling` (làm mát) và `waterproof` (0–1). Nội dung: Áo lông (lông thú), Mũ lông, Áo mát (lá), Nón lá chống mưa, Hỏa lô cầm tay (cầm tay, tỏa nhiệt, tốn than).
5. **Nguồn nhiệt và lạnh:** lửa trại, bếp lửa sưởi theo bán kính; công trình **Băng khối** (đặt xuống, tan dần, làm mát vùng quanh).
6. **Thời tiết** (`state.weather`): `clear`, `rain`, `snow`, `storm`. Mưa: Đạo Tâm tụt thêm (giảm theo `waterproof`), lửa ngoài trời cháy nhanh hơn. Tuyết: Đông và Tuyết Lĩnh, lạnh thêm. **Sét ở Lôi Trì** quanh năm và khi bão: chọn điểm ngẫu nhiên gần người chơi trong biome Lôi Trì, có vùng cảnh báo 2 giây rồi giáng, gây sát thương và đốt cháy công trình gỗ.
7. **Trụ Dẫn Lôi** (giai đoạn này sở hữu): công trình bậc 2 từ Lôi Tinh Thạch và đá. Sét giáng trong bán kính 10 m rơi vào trụ thay vì người chơi, mỗi lần nạp 1 điểm; tương tác lấy ra **Lôi Tinh Thạch nạp điện** (dùng ở 05 và 08). Giai đoạn 08 dùng lại trụ này cho Thiên Kiếp.
8. **Hạ:** công trình gỗ và cây có xác suất nhỏ tự bốc cháy khi nhiệt môi trường trên 80 và không có Thủy Dẫn Trận gần (trận làm ở 05; tới lúc đó chỉ kiểm tra băng khối gần). Lửa lan sang công trình gỗ kề.
9. **Đông:** mặt nước đóng băng: suối Linh Tuyền ngoài Hỏa Sơn đóng băng, múc phải đập băng bằng cuốc (thêm 3 nhát).
10. **Hư hỏng thực phẩm:** `ItemDef.spoil_time` (giây, 0 = không hỏng). Mỗi ô đồ ăn giữ `freshness` 1→0. Dưới 0,5 là "ôi" (hồi ít hơn), về 0 thành **Thức ăn hỏng** (dùng làm phân bón ruộng). Rương thường làm chậm 0; công trình **Hầm băng** mới (Tuyết Lĩnh hoặc có băng khối) làm chậm 50%; tuyết rét (nhiệt môi trường dưới 20) làm chậm 25%. Quả tưới Huyền Băng Tuyền lâu hỏng gấp đôi. Linh Thủy mất linh tính sau 3 ngày trong bình thường (đã có trong GDD 5).
11. **Bùa giấy ẩm mùa Xuân:** khung `soak` trên vật phẩm có thẻ `paper`; nội dung bùa thêm ở 05, giai đoạn này chỉ viết luật và test bằng giấy bùa.
12. **Huyết Mạch Cổ Thú chịu thời tiết** (GDD 9): mưa bão làm cuồng tính dâng nhanh hơn (tăng tốc tụt Đạo Tâm 25%).
13. **Lưu:** `state.clock.season`, `season_day`, `state.weather`, `stats.temperature`, `freshness` mỗi ô. `SAVE_VERSION` 4, chuyển đổi gán mùa Thu và freshness 1.

## Các bước

1. `SeasonDef` + 4 file mùa. `world/simulation/world_season.gd` (mùa, pha). Đổi `game_world.step` dùng file này.
2. `world/simulation/world_temperature.gd` (môi trường + thân nhiệt + cóng/say nắng).
3. Ô `head`, thuộc tính đồ mặc trong `ItemDef`, nội dung đồ mặc, Hỏa lô, Băng khối, Hầm băng.
4. `world/simulation/world_weather.gd` (chọn thời tiết theo mùa/biome mỗi nửa ngày, mưa, tuyết, sét, cháy).
5. Trụ Dẫn Lôi.
6. `world/simulation/world_spoilage.gd` (freshness theo nơi chứa).
7. HUD: mùa, ngày còn lại, nhiệt kế, biểu tượng thời tiết; view: hạt mưa, tuyết, chớp cảnh báo sét, màu trời theo mùa.

## Kiểm chứng

- `tests/test_seasons.gd`: sau 20 ngày Thu chuyển Đông; pha Đông đúng 5/5/6; báo trước đúng 3 ngày.
- `tests/test_temperature.gd`: đứng ngoài trời Đông không áo thì nhiệt giảm dưới 15 và mất máu; gần lửa thì không; Áo lông làm chậm tụt; Hỏa Sơn mùa Hạ say nắng; uống Huyền Băng thì mát.
- `tests/test_weather.gd`: sét có cảnh báo trước khi giáng; trụ Dẫn Lôi hút sét trong bán kính; mưa tăng tốc tụt Đạo Tâm và giảm theo `waterproof`.
- `tests/test_spoilage.gd`: thịt hỏng sau `spoil_time`; trong Hầm băng hỏng chậm gấp đôi; giấy bùa ngoài rương mùa Xuân hỏng dần.

## Rủi ro

- Nhiều hệ thống cùng đổi chỉ số người chơi (mưa, nhiệt, sương độc). Gom các nguồn cộng/trừ vào một bước tổng hợp `modifiers` mỗi giây để dễ test và tránh trừ hai lần.
- Freshness trên từng ô làm patch mạng đổi liên tục. Chỉ đồng bộ freshness làm tròn 0,05 (đổi bậc mới `touch`).

## Hoàn tác

Mùa và nhiệt là file mới; đặt `options.seasons = false` trả về pha cố định cũ khi cần dò lỗi.
