# Giai đoạn 07 — Thức ăn & nấu nướng

## Mục tiêu
Ăn đồ sống, nướng trên lửa, nấu Nồi Linh Thực kiểu crockpot theo thẻ thuộc tính.

## Việc cần làm
1. **Giá trị thức ăn trong ItemDef:** hồi Thể Lực, Khí Huyết, Đạo Tâm (có thể âm). Đồ sống thường kém hoặc trừ Đạo Tâm.
2. **Nướng trên lửa trại:** cầm đồ sống, bấm vào lửa thì ra đồ chín (quả nướng, thịt nướng, nấm nướng).
3. **Hệ thẻ:** mỗi nguyên liệu có thẻ kèm giá trị, ví dụ quả linh có Quả 1, thịt nhỏ có Thú 0.5, nấm có Mộc 0.5. Thẻ đặt trong ItemDef từ giai đoạn 03.
4. **Bộ khớp công thức (logic thuần, dùng lại cho Lò Đan):** đầu vào 4 nguyên liệu. Mỗi công thức có điều kiện tối thiểu/tối đa theo thẻ và có thể cấm thẻ. Lấy công thức khớp có độ ưu tiên cao nhất. Nhiều công thức cùng ưu tiên thì chọn ngẫu nhiên theo trọng số. Không khớp gì thì ra Món Cháy.
5. **Nồi Linh Thực:** bỏ 4 nguyên liệu, bấm nấu, chờ thời gian nấu, lấy món ra. Nhiều người dùng chung, host xử lý.
6. **Công thức demo (khoảng 6 món):** Canh Linh Quả, Thịt Hầm Nấm, Củ Hấp, Linh Thực Tổng Hợp, Món Cháy... Mỗi món hồi chỉ số khác nhau và có buff nhẹ (ví dụ đỡ tụt Đạo Tâm một lúc).
7. **Thiên Thư:** hiện công thức nồi, đánh dấu khi nấu thành công lần đầu.
8. Test GUT cho bộ khớp công thức: đúng món, ưu tiên, thẻ bị cấm, không khớp thì ra Món Cháy.

## Hoàn thành khi
- Nấu ra đủ 6 món theo công thức trong Thiên Thư. Bộ khớp công thức qua toàn bộ test.

## Rủi ro
- Bộ khớp công thức phải viết tổng quát ngay từ đầu để giai đoạn 09 (Lò Đan) dùng lại.
