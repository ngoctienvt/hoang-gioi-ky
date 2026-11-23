# UI hoang cổ — 2026-11-23

- Mục tiêu: icon dùng thật trong Godot; HUD dễ đọc theo phân vùng ảnh tham khảo, giữ bản sắc Hoang Giới Ký.
- Ràng buộc: giữ gameplay/mạng/dữ liệu người dùng; không sao chép asset DST; nền tối, đồng cũ, điểm nhấn ngọc; chữ dùng hệ dịch hiện tại.
- Ngoài phạm vi: vẽ lại thế giới 3D, thay cơ chế chế tác, thêm tính năng gameplay.
- Đạt khi: mỗi ItemDef có icon hợp lệ; ô đồ hiển thị icon/số lượng/trạng thái; danh mục chế tác có icon; HUD không dùng tên đồ dài trong hotbar; có bảng xem asset và mô tả bố cục.

## Các bước

1. Đã tạo 180 icon SVG 96×96 trong suốt, manifest nguồn và bảng xem. Icon cùng họ dùng chung silhouette, khác màu/chất liệu/dấu bậc.
2. Đã gắn 164 ItemDef, UI túi đồ/chế tác/chỉ số, chỉnh khung và khoảng cách.
3. Đã kiểm tra XML, đường dẫn tài nguyên, độ phủ ItemDef; review diff. Không chạy game/test/compile theo yêu cầu được ghi trong README. Chờ kiểm tra thị giác runtime; browser chặn mở HTML local.

## Kiểm chứng

Kiểm tra tĩnh asset và liên kết; ảnh concept là định hướng, không phải ảnh chụp runtime. Chưa gọi asset production-ready cho đến khi chủ dự án xem trong game.
