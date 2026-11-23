# Giai đoạn 05 — Chế tác & công trình

## Mục tiêu
Menu chế tác kiểu DST, có bậc mở khóa qua Bàn Chế Tác. Chế được công cụ và dựng được công trình. Thiên Thư (wiki) ghi nhận món đã chế.

## Việc cần làm
1. **RecipeDef:** sản phẩm, số lượng, nguyên liệu, bậc yêu cầu (0 = tay không, 1 = gần Bàn Chế Tác), nhóm (Công cụ, Ánh sáng, Sinh tồn, Chiến đấu, Công trình), là công trình hay vật phẩm.
2. **Công thức demo:**
   - Bậc 0: Rìu đá, Cuốc đá, Đuốc, Lửa Trại, Bàn Chế Tác, dây thừng.
   - Bậc 1: Xẻng, Giáo, Giáp cỏ, Rương, Lò Lửa (lửa trại bền), Nồi Linh Thực, Lò Đan, Ruộng Linh Thảo, Bình Đựng Nước, Hồi Hồn Đài.
   - Con số nguyên liệu cụ thể đặt trong file dữ liệu, cân chỉnh khi chơi thử.
3. **Menu chế tác:** tab theo nhóm bên trái màn hình. Món đủ nguyên liệu thì sáng, thiếu thì mờ và hiện nguyên liệu còn thiếu. Bậc chưa đạt thì hiện khóa.
4. **Bàn Chế Tác:** đứng trong bán kính thì mở bậc 1.
5. **Đặt công trình:** hiện bóng mờ theo chuột, đỏ khi không đặt được (chồng lên vật khác, nước). Host kiểm tra và tạo công trình. Có thể đập bỏ công trình bằng búa (thu lại một phần nguyên liệu, búa làm ở bậc 1).
6. **Lửa trại:** cháy theo nhiên liệu, thêm gỗ, cỏ, cành để cháy lâu hơn, nhỏ dần rồi tắt. Phát sáng (nối với hệ ánh sáng ở giai đoạn 06).
7. **Rương:** kho chung, nhiều người mở cùng lúc, đồng bộ qua host.
8. **Thiên Thư (wiki):** giao diện xem mọi công thức (chế tác, nồi, lò đan) có sẵn ngay từ đầu. Chế thành công lần đầu thì đánh dấu đã chế cho cả nhóm.
9. Test GUT: kiểm tra đủ nguyên liệu, trừ nguyên liệu đúng, kiểm tra bậc.

## Hoàn thành khi
- Từ tay trắng chế được Rìu đá, Cuốc đá, Lửa Trại, Bàn Chế Tác, rồi lên bậc 1 chế Rương và Xẻng.
- Hai người cùng đặt công trình ở hai chỗ khác nhau, không lỗi chồng lấn.
- Thiên Thư hiện đúng các món đã chế.

## Rủi ro
- Trừ nguyên liệu phải làm ở host, trong một bước, để không bị chế hai lần khi mạng trễ.

## Tiến độ triển khai — 2026-11-23

**Trạng thái:** Đã triển khai, chờ chủ dự án kiểm tra gameplay.

**Mã nguồn:** autoload/recipe_db.gd; data/recipes/; world/simulation/world_structures.gd; world_combat.gd; ui/demo/demo_recipes.gd. Bậc chế tác, đặt công trình, nhiên liệu, rương, phá bằng búa và Thiên Thư.

**Chủ dự án kiểm tra:** Bàn chế tác mở/khóa bậc theo khoảng cách; đặt hai công trình không chồng; thử rương dùng chung và tiếp nhiên liệu.


- [x] Đã triển khai phần mã nêu trong mục tiến độ.
- [ ] Chủ dự án xác nhận gameplay và tiêu chí hoàn thành.
