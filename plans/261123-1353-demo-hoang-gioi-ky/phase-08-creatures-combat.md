# Giai đoạn 08 — Yêu thú & chiến đấu

## Mục tiêu
Đánh nhau cơ bản kiểu DST. Ba loài yêu thú có tập tính riêng, rơi nguyên liệu thô.

## Việc cần làm
1. **Chiến đấu:** chuột trái đánh mục tiêu trong tầm. Sát thương theo vũ khí trên tay (tay không yếu). Đánh có thời gian hồi giữa các đòn. Giáp cỏ giảm sát thương nhận vào. Trúng đòn có nháy đỏ và đẩy lùi nhẹ. Không có PvP: đòn không gây sát thương cho đồng đội.
2. **HealthComponent** dùng chung cho người chơi, yêu thú, công trình.
3. **Khung AI:** máy trạng thái đơn giản (đi lang thang, chạy trốn, đuổi theo, tấn công, về hang). Host chạy AI, client chỉ nhận vị trí và hoạt ảnh.
4. **CreatureDef:** máu, sát thương, tốc độ, tầm phát hiện, giờ hoạt động, đồ rơi.
5. **Ba loài:**
   - **Thỏ linh:** sống theo bầy quanh hang, thấy người thì chạy về hang. Ban đêm ở trong hang. Rơi thịt nhỏ. (Bẫy thỏ nếu còn thời gian.)
   - **Sói rừng:** đi theo bầy 2–3 con, săn lúc chạng vạng và đêm, đuổi người chơi khi vào tầm. Ban ngày ngủ ở ổ. Rơi thịt, da lông, răng sói.
   - **Khỉ linh:** sống quanh cây linh quả, nhặt trộm đồ rơi dưới đất rồi mang về ổ, chạy khi bị đánh. Rơi lông khỉ và đồ đã trộm.
6. **Hồi sinh quần thể:** hang thỏ và ổ sói sinh lại thú theo thời gian để không bị diệt sạch.
7. Thêm Giáo, Giáp cỏ (nếu chưa có ở giai đoạn 05) và vật phẩm rơi vào dữ liệu.

## Hoàn thành khi
- Ba loài hành xử đúng tập tính ở host và client.
- Đánh chết được sói bằng giáo, bị sói đánh chết được.
- Khỉ nhặt đồ dưới đất rồi mang về ổ, đánh khỉ lấy lại được đồ.

## Rủi ro
- Đồng bộ nhiều yêu thú tốn băng thông: chỉ đồng bộ vị trí với tần suất thấp và nội suy ở client.

## Tiến độ triển khai — 2026-11-23

**Trạng thái:** Đã triển khai, chờ chủ dự án kiểm tra gameplay.

**Mã nguồn:** data/creatures/; world/simulation/world_creatures.gd; world_combat.gd; world_life.gd. Thỏ/sói/khỉ, đồ rơi, trộm đồ, hồi quần thể, giáp/vũ khí, không PvP thường.

**Chủ dự án kiểm tra:** Đánh sói bằng giáo, bị sói đánh, khỉ trộm và trả đồ khi chết; kiểm tra hồi quần thể và giáp giảm sát thương.


- [x] Đã triển khai phần mã nêu trong mục tiến độ.
- [ ] Chủ dự án xác nhận gameplay và tiêu chí hoàn thành.
