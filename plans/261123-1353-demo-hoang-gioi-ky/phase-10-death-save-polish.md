# Giai đoạn 10 — Chết, lưu game & hoàn thiện demo

## Mục tiêu
Chết và hồi sinh, lưu và tải thế giới, hoàn thiện để chơi thử co-op 2–4 người.

## Việc cần làm

### A. Chết & hồi sinh
1. Chết: rơi toàn bộ đồ tại chỗ, nhân vật thành **Hồn Phách** (bay, bán trong suốt, không nhặt, không đánh).
2. Hồi sinh bằng **Hoàn Hồn Đan** (đồng đội dùng lên Hồn Phách) hoặc **Hồi Hồn Đài** (Hồn Phách bay tới, tốn nguyên liệu mỗi lần).
3. Mỗi lần hồi sinh giảm 25% Khí Huyết tối đa, tối đa 2 lần. Hồi lại dần khi ngủ (nếu có túi ngủ cỏ) hoặc qua ngày.
4. **Cả nhóm chết:** theo tùy chọn chọn lúc tạo thế giới. Reset thì về màn hình tạo thế giới mới. Chơi tiếp thì hồi sinh cả nhóm tại điểm xuất phát hoặc Hồi Hồn Đài, phạt Khí Huyết tối đa.

### B. Lưu & tải
1. **SaveManager (chỉ host):** lưu seed, thời gian, trạng thái điểm tài nguyên đã thay đổi, công trình, đồ dưới đất, yêu thú, kho đồ và chỉ số từng người chơi (theo tên người chơi), Thiên Thư.
2. Tự lưu mỗi đầu ngày và khi host thoát. Màn hình chính có danh sách thế giới đã lưu.
3. Người chơi vào lại với cùng tên thì nhận lại nhân vật cũ.
4. Test GUT: lưu rồi tải ra cùng trạng thái.

### C. Hoàn thiện
1. Rà toàn bộ chữ hiển thị đi qua khóa dịch tiếng Việt.
2. Âm thanh cơ bản: chặt, đào, nhặt, đánh, lửa, cảnh báo Hắc Ám.
3. Tùy chọn khi tạo thế giới: seed, cả nhóm chết thì Reset hoặc Chơi tiếp, độ dài ngày (cho thử nghiệm).
4. Cân chỉnh số liệu (số nhát chặt, tốc độ đói, lượng nguyên liệu) sau khi chơi thử.
5. Xuất bản build Windows để gửi cho người chơi thử.
6. **Chơi thử co-op 2–4 người trên LAN hoặc qua IP:** sống sót 10 ngày mùa Thu. Ghi lại lỗi và cảm nhận vào `plans/reports/`.

## Hoàn thành khi
- Đạt toàn bộ tiêu chí hoàn thành trong [plan.md](plan.md).
- Build Windows chạy được trên máy khác, 2 máy vào cùng thế giới.

## Rủi ro
- Chơi qua mạng Internet (không phải LAN) cần host mở port. Ghi hướng dẫn mở port trong README cho người thử. Steam P2P để sau demo.

## Tiến độ triển khai — 2026-11-23

**Trạng thái:** Đã triển khai phần chết/lưu/âm thanh/tùy chọn; còn build Windows và chơi thử LAN 10 ngày.

**Mã nguồn:** world/simulation/world_life.gd; autoload/save_manager.gd; world/demo_session.gd; entities/demo/demo_audio.gd; ui/demo/demo_menu.gd. Lưu host bằng tên người chơi, tự lưu đầu ngày/thoát; Hồn Phách/hồi sinh và phạt máu.

**Chủ dự án kiểm tra:** Kiểm tra lưu/tải/đổi peer giữ cùng tên; Hoàn Hồn Đan/đài tiêu hao vật liệu; cả nhóm chết theo tùy chọn. Xuất Windows, chạy máy khác và chơi LAN/IP 2–4 người qua 10 ngày Thu.


- [x] Đã triển khai phần mã nêu trong mục tiến độ.
- [ ] Chủ dự án xác nhận gameplay và tiêu chí hoàn thành.
- [ ] Xuất Windows, chạy trên máy khác.
- [ ] LAN/IP 2–4 người qua 10 ngày Thu.
