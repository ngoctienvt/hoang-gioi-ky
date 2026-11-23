# Bản game đủ chức năng tối thiểu (feature-complete greybox)

- **Trạng thái:** Hoàn thành (tất cả 10 giai đoạn đã xong)
- **Ngày lập:** 2026-11-23
- **Yêu cầu của chủ dự án:** làm game hoàn thiện tối thiểu, có **đầy đủ chức năng** để chơi được. **Không cần cân bằng.** Chủ dự án chưa tự chơi thử ở bước này.
- **Nguồn thiết kế:** [GDD](../../docs/game-design-document.md), [lộ trình](plan.md)

## Định nghĩa "đủ chức năng tối thiểu"

Mọi hệ thống trong GDD đều có và chơi được từ đầu đến cuối, mỗi hệ thống có lượng nội dung **ít nhất** đủ để chạy. Hình ảnh dùng khối đơn giản theo art direction hiện tại (GDD 1.1). Số liệu chỉ cần hợp lý để chơi được, không cần cân bằng.

**Nằm ngoài phạm vi:** Steam P2P (vẫn dùng ENet qua IP/LAN), bản tiếng Anh (vẫn đi qua khóa dịch), art, animation và nhạc hoàn chỉnh, cân bằng số liệu.

## Tiêu chí hoàn thành

1. Thế giới sinh theo seed với **6 biome** nối nhau. Mỗi biome đủ 5 lớp tài nguyên, có 1 Linh Tuyền riêng và ít nhất 2 loài yêu thú có tập tính riêng. Có Cổ Truyền Tống Trận nối các vùng.
2. Đủ **4 mùa** theo bảng GDD 7.4, có **nhiệt độ** (lạnh, nóng), thời tiết (mưa, tuyết, sét ở Lôi Trì) và **hư hỏng thực phẩm**.
3. Đủ **4 nhân vật** với năng lực và cái giá theo GDD mục 9. Chọn nhân vật khi vào thế giới.
4. **Thức Tỉnh 3 tầng** với nghi thức Kiếp Nạn và Thiên Kiếp cùng lúc. Mỗi tầng có cây kỹ năng nhánh loại trừ. Có **Ấn Ký** tối đa 3 ô, làm từ nguyên liệu Boss.
5. **Tâm Ma** có dấu hiệu rõ (viền mực). **Nhân Quả** hai thanh Nghiệp và Duyên, đủ ba ngưỡng 30/60/100, sự kiện tiêu điểm, giảm dần theo thời gian, hiển thị bằng mây trên Sơn Môn. Có thương nhân và thế lực xuất hiện qua sự kiện.
6. Ít nhất **1 Boss mỗi biome** (6 Boss), có cơ chế riêng và rơi nguyên liệu đặc trưng. Có **Bí Cảnh** vào được và ra được.
7. Đủ **7 nhóm đan dược** (GDD 6.5), **Bàn Vẽ Phù** và bùa, **Khôi Lỗi** (vận chuyển, chặt, đào) và **Pháp Trận**, đủ công trình Sơn Môn trong GDD 6.7.
8. Tôi vũ khí bằng cả 6 loại Linh Thủy, mỗi loại một hiệu ứng.
9. Lưu và tải toàn bộ trạng thái trên. File lưu có số phiên bản.
10. Bốn người chơi qua LAN không bị nghẽn mạng trên bản đồ đủ 6 biome. Phải có bài test băng thông chứng minh điều này.
11. Có menu chính, menu cài đặt (âm lượng, đồ họa cơ bản, đổi phím) và hướng dẫn chơi lần đầu ngắn. Xuất bản Windows chạy được.
12. GUT test cho logic của từng hệ thống mới. Toàn bộ test qua ở chế độ headless.

## Các giai đoạn (làm tuần tự, mỗi giai đoạn một commit)

| # | Giai đoạn | Nội dung |
|---|---|---|
| 01 | Nền móng | Đổi tên `demo_*` thành tên hệ thống thật. Tách các file sát 200 dòng. Thêm phiên bản và chuyển đổi cho file lưu. Viết bài test băng thông (vài nghìn thực thể, 4 peer). Đổi đồng bộ từ gửi cả nhóm trạng thái sang gửi thay đổi theo từng thực thể và chỉ gửi vùng gần người chơi |
| 02 | Thế giới 6 biome | Chia bản đồ theo vùng. Ghép biome từ mảnh đặt sẵn theo seed. Thêm tài nguyên, thức ăn, 6 Linh Tuyền và Cổ Truyền Tống Trận |
| 03 | Mùa, nhiệt độ, thời tiết | Đủ 4 mùa, nhiệt độ cơ thể, áo ấm và áo mát, lửa sưởi, mưa, tuyết, sét. Thêm hư hỏng thực phẩm |
| 04 | Yêu thú các biome | Ít nhất 2 loài mỗi biome với tập tính trong GDD mục 4. Thêm nguyên liệu rơi |
| 05 | [Chế tác mở rộng](phase-05-che-tac-mo-rong.md) | 7 nhóm đan, Bàn Vẽ Phù và bùa, Khôi Lỗi, Pháp Trận, công trình Sơn Môn, tôi vũ khí bằng 6 loại Linh Thủy |
| 06 | [Tâm Ma & Nhân Quả](phase-06-tam-ma-nhan-qua.md) | Tâm Ma, hai thanh Nhân Quả, bảng sự kiện cho ba ngưỡng, thương nhân, thế lực |
| 07 | [Nhân vật](phase-07-nhan-vat.md) | Thực Hồn Nhân, Ngự Khí & Khôi Lỗi Sư, Âm Dương Thể. Màn chọn nhân vật |
| 08 | [Thức Tỉnh](phase-08-thuc-tinh.md) | 3 tầng, nghi thức Kiếp Nạn và Thiên Kiếp riêng cho từng nhân vật, cây kỹ năng, Ấn Ký |
| 09 | [Boss & Bí Cảnh](phase-09-boss-bi-canh.md) | 6 Boss và Bí Cảnh |
| 10 | [Hoàn thiện](phase-10-hoan-thien.md) | Menu, cài đặt, hướng dẫn chơi, rà khóa dịch, chạy toàn bộ test, xuất bản Windows, thử 2 tiến trình host và client chơi cùng |

## Nguyên tắc

- Giữ kiến trúc host quyết định và phần mô phỏng thế giới tách khỏi scene, để test được không cần render.
- Nội dung mới (vật phẩm, công thức, yêu thú, Boss, sự kiện, kỹ năng) là Resource `.tres` trong `data/`.
- File code dưới 200 dòng. Mọi chữ hiển thị đi qua `tr()`.
- Mỗi giai đoạn chạy GUT, chạy main scene headless, rồi commit theo conventional commits. Không push.
- Ý tưởng mới ngoài GDD thì ghi vào GDD, không tự làm thêm.
