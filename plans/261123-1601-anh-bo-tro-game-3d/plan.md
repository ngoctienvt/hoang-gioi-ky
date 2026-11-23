# Ảnh bổ trợ cho game 3D

- Mục tiêu: tạo ảnh thực dùng trong UI, bổ sung cho model 3D do chủ dự án đang tạo.
- Phạm vi: nền menu hoang cổ, icon Hóa Thú và Thú Giác; tích hợp vào menu/nút kỹ năng hiện có.
- Giữ nguyên: model, gameplay, dữ liệu lưu, luồng host/join. Chưa làm portrait vì ngoại hình model chưa chốt.
- Mỹ thuật: đất/ô liu/than trầm, đồng cũ, ngà, điểm nhấn ngọc; không kiến trúc tông môn, không chữ vẽ sẵn.
- Kiểm tra: kích thước PNG, alpha icon, xem ảnh nguồn, đường dẫn và diff. Không chạy game/test/compile theo README.

## Tiến độ

- Đã tạo 3 ảnh bằng image_gen tích hợp và lưu trong workspace.
- Đã chuẩn hóa icon 192px, kiểm tra alpha thật, xem nguồn và contact sheet 192/48/32px; giữ nguồn, prompt và manifest.
- Đã tích hợp nền menu và hai icon kỹ năng. Không thêm luồng hay gameplay mới.
- Kiểm tra tĩnh đường dẫn/diff; runtime chưa chạy theo README.
