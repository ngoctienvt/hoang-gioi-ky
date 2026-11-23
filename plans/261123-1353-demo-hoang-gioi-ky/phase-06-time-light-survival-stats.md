# Giai đoạn 06 — Thời gian, ánh sáng & chỉ số sinh tồn

## Mục tiêu
Đồng hồ ngày đêm theo DST, ánh sáng thời gian thực, Hắc Ám ăn người trong bóng tối, ba chỉ số sinh tồn và HUD.

## Việc cần làm
1. **GameClock (host chạy, đồng bộ xuống):** 1 ngày = 8 phút, 16 phần × 30 giây. Mùa Thu: 8 phần ngày, 6 phần chạng vạng, 2 phần đêm. Đếm ngày, mùa và ngày trong mùa. Có tốc độ nhanh để thử nghiệm (chỉ ở bản dev).
2. **Ánh sáng:** đèn mặt trời đổi màu và độ sáng theo pha. Đêm gần như tối hẳn. Lửa trại, Đuốc là nguồn sáng có bán kính.
3. **Hắc Ám:** người chơi đứng ngoài mọi vùng sáng vào ban đêm. Sau vài giây cảnh báo (tiếng động, viền màn hình) thì bị đánh, mất nhiều Khí Huyết mỗi đòn. Kiểm tra theo bán kính các nguồn sáng.
4. **Chỉ số (component trên người chơi, host tính):**
   - **Khí Huyết:** tối đa theo nhân vật. Mất khi bị đánh, Hắc Ám, đói kiệt. Hồi bằng ăn và đan.
   - **Thể Lực:** giảm đều theo thời gian (đói). Về 0 thì mất Khí Huyết dần. Thấp thì chạy chậm.
   - **Đạo Tâm:** giảm trong bóng tối và khi ở gần yêu thú hung, hồi khi đứng gần lửa và ban ngày. Demo chỉ cần thanh chạy đúng (Tâm Ma để sau).
5. **HUD:** ba biểu tượng chỉ số tròn, khung viền vàng đồng (theo GDD mục 1.1), đồng hồ tròn chia 16 phần màu theo pha, số ngày và mùa.
6. Nối thời gian mọc lại của giai đoạn 04 vào `GameClock`.
7. Test GUT cho đồng hồ (tính pha theo thời điểm) và chỉ số (giảm, giới hạn, chạm 0).

## Hoàn thành khi
- Chơi qua một ngày đủ ba pha. Đứng trong bóng tối ban đêm bị đánh, đứng cạnh lửa thì an toàn.
- Ba thanh chỉ số chạy đúng và giống nhau ở host và client.

## Rủi ro
- Tính vùng sáng cho Hắc Ám không dựa vào render; dùng danh sách nguồn sáng và bán kính để host tính được.
