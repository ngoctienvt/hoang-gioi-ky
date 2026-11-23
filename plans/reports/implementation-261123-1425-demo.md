# Triển khai demo — 2026-11-23

- Trạng thái: đã có phần mã giai đoạn 02–09; chờ chủ dự án chơi thử. Giai đoạn 10 còn xuất Windows và LAN/IP 10 ngày.
- Đã có: ENet host quyết định, nhân vật/camera, kho 15 ô/trang bị/độ bền, tài nguyên, chế tác/công trình/rương, ngày đêm/sinh tồn, nấu/luyện đan, thú/chiến đấu, Hóa Thú/Thú Giác, tuyền/ruộng/Sinh Cơ, chết/hồi sinh/lưu tải.
- Main scene `world/demo.tscn`; giao diện lấy cảm hứng DST; dùng lại cảnh phong cách qua `entities/demo/demo_style.gd`. Component thực tế: inventory/survival; gameplay khác ở `world/simulation/`.
- Dữ liệu: 56 vật phẩm, 17 công thức chế tác, 5 món + Món Cháy, 4 công thức đan, 10 loại tài nguyên, 3 loài thú.
- Sửa tích hợp: ăn/trang bị, tỉ lệ đan, khai thác cạn, phạt hồi sinh, gộp chồng có metadata, nước hết linh tính, UI ruộng/đài/Thiên Thư; quét Resource tương thích export và thẻ wiki tiếng Việt.
- Sửa cuối: dọn vật cản/cảnh/preview khi rời phiên; preview đặt dùng cùng bán kính host; slot lưu lỗi trả lỗi thay vì tạo thế giới mới.
- Kết quả lịch sử trước yêu cầu dừng: GUT 28/28, 173 assertions. Có thay đổi code/UI sau mốc này; không coi số đó là kiểm chứng bản cuối.
- Theo yêu cầu chủ dự án: không chạy thêm game/test/compile/UI trong bước chốt này; không commit.

## Chủ dự án kiểm tra

1. Mở demo, kiểm tra giao diện, Tab/B/Space/WASD/Q/F và tương tác chuột phải; đi từ tay trắng tới bàn chế tác/lửa trại.
2. Hai người cùng nhặt/chặt/đặt/rương/nồi; công cụ hỏng; cả ba pha ngày và an toàn gần lửa.
3. Săn thú, khỉ trộm đồ; Hóa Thú/Thú Giác/cuồng tính; luyện đan, tưới/bón/thu hoạch và Sinh Cơ.
4. Chết/hồi sinh bằng đan/đài; tùy chọn cả nhóm chết; lưu/tải và vào lại đúng tên.
5. Xuất Windows, kiểm tra nội dung Resource trong bản xuất, chạy máy khác và LAN/IP 2–4 người qua 10 ngày Thu.

Đã đồng bộ cả 10 phase. CLI cập nhật trạng thái plan `in-progress` và chỉ mục; bảng legacy/ghi chú tiến độ cập nhật trực tiếp vì CLI không có lệnh sửa ô trạng thái bảng. Không quy đổi danh sách yêu cầu cũ thành tỷ lệ hoàn thành giả.

Còn mở: gameplay/cân bằng do chủ dự án xác nhận; Windows build và LAN 10 ngày.
