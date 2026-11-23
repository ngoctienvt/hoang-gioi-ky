# Lộ trình: từ demo đến game hoàn chỉnh — Hoang Giới Ký

- **Trạng thái:** Đề xuất, chờ chủ dự án chốt các câu hỏi ở cuối
- **Ngày lập:** 2026-11-23
- **Nguồn:** [GDD](../../docs/game-design-document.md) mục 14, danh sách Non-goals trong [plan demo](../261123-1353-demo-hoang-gioi-ky/plan.md), kết quả rà soát ngày 2026-11-23

## Hiện trạng (rà ngày 2026-11-23)

- Code demo giai đoạn 02–09 đã có, đi theo đúng kiến trúc host quyết định. GUT qua **28/28** (173 assertion) trên cây làm việc hiện tại. Chạy headless main scene `world/demo.tscn` 300 khung hình không có lỗi.
- `godot-cli check` báo 19 lỗi "Identifier not found" cho các autoload. Đây là báo lỗi sai: công cụ check biên dịch script riêng lẻ, không nạp autoload. Game và test vẫn chạy bình thường.
- **Chưa xong:** 33 file sửa và vài file mới **chưa commit** trên `main`. Chưa xuất bản Windows. Chưa chơi LAN 2–4 người qua 10 ngày. Chủ dự án chưa chơi thử để chấm cảm giác.
- **Giới hạn kiến trúc** (điểm khác biệt chính giữa demo và game đầy đủ):
  - Toàn bộ thế giới là một `Dictionary` lớn chạy trong `DemoWorld`. Cách này **nên giữ**, vì nó giúp test logic host không cần scene.
  - `demo_session.gd::_publish` so sánh sâu và sao chép sâu từng nhóm trạng thái (nodes, structures, creatures). Chỉ cần một thứ trong nhóm đổi là gửi lại **cả nhóm** qua kênh reliable. Bản đồ demo chỉ vài trăm thực thể. Sáu biome với hàng nghìn thực thể sẽ nghẽn ở đây.
  - Tên `demo_*` có ở khắp nơi. `demo_session.gd` (199 dòng), `demo_ui.gd` (194) và `demo_main.gd` (190) đã sát giới hạn 200 dòng, nên tính năng nào thêm vào cũng phải tách file trước.
  - Các thư mục `entities/*` gần như trống. Hình khối và cảnh được dựng bằng code (`demo_meshes.gd`), chưa có quy trình nạp asset 3D thật.
  - File lưu chưa có số phiên bản hay cơ chế chuyển đổi. Phải có trước khi người chơi giữ thế giới lâu dài.

## Các mốc (xếp theo phụ thuộc)

| # | Mốc | Nội dung chính | Phụ thuộc |
|---|---|---|---|
| M0 | **Chốt demo** | Chủ dự án chơi thử và ghi lỗi. Commit phần việc đang dở. Xuất bản Windows và kiểm tra Resource nạp được trong bản xuất. Chơi LAN 2–4 người qua 10 ngày Thu. Ghi báo cáo vào `plans/reports/` | — |
| M1 | **Nền móng cho game lớn** | (1) Bài **stress test** đo băng thông: vài nghìn thực thể, 4 người, đo byte/giây. Dựa vào số đo để chọn giữa đồng bộ thay đổi theo từng thực thể và chỉ gửi vùng gần người chơi (interest management), hoặc kết hợp cả hai. (2) Đổi `demo_*` thành tên hệ thống thật, tách UI và session thành module. (3) Thêm phiên bản và chuyển đổi cho file lưu. (4) Chia bản đồ thành vùng (chunk) để sinh và tải theo vùng. (5) Quy trình nạp asset 3D thật (nối với [plan asset Hunyuan3D](../261123-1413-3d-asset-pipeline-hunyuan3d-omni/plan.md)): scene cho từng loại thực thể, LOD, animation | M0 |
| M2 | **Vertical slice** (theo GDD 14.3) | Thêm biome U Minh Đầm Lầy với đủ 5 lớp tài nguyên và Linh Tuyền thứ 2. Chuyển mùa Thu sang Đông cùng **nhiệt độ** (lửa, áo, đồ ăn nóng). Thêm Thực Hồn Nhân. **Thức Tỉnh tầng Sơ** với nghi thức Kiếp Nạn và Thiên Kiếp cùng lúc. **Tâm Ma** có dấu hiệu rõ. Bàn Vẽ Phù và bùa cơ bản. 1 Khôi Lỗi vận chuyển. Thanh Nhân Quả ngưỡng 30. Boss **U Minh Quỷ Tướng**. Hư hỏng thực phẩm | M1 |
| M3 | **Chơi thử co-op và cân bằng** | Nhóm 2–4 người chơi bản slice. Chấm cảm giác điều khiển, độ mượt mạng, tốc độ tụt chỉ số, nhịp chế tác và trận Boss. Ghi số liệu cân bằng vào file dữ liệu, không ghi cứng trong code | M2 |
| M4 | **Mở rộng nội dung** (theo gói) | Gói A: Xích Viêm Hỏa Sơn, mùa Hạ, Âm Dương Thể. Gói B: Hàn Băng Tuyết Lĩnh và Lôi Trì Thạch Cốc, mùa Xuân, Ngự Khí & Khôi Lỗi Sư. Gói C: Hoang Cổ Di Tích, Bí Cảnh, Thức Tỉnh tầng Trung và Toàn, Ấn Ký, Nhân Quả ngưỡng 60 và 100, các Boss còn lại, Pháp Trận | M3 |
| M5 | **Phát hành** | Steam P2P qua GodotSteam (bỏ việc mở port). Bản tiếng Anh. Art, animation và âm thanh hoàn chỉnh, nhạc nền. Menu cài đặt (đồ họa, âm lượng, đổi phím, tay cầm). Hướng dẫn chơi lần đầu. Tối ưu hiệu năng. Thành tựu Steam, trang cửa hàng, khai báo nội dung AI | M3 (có thể chạy song song với M4) |

Ghi chú về thứ tự:
- Nền móng (M1) phải đi trước việc thêm biome, vì mỗi biome làm số thực thể tăng gấp nhiều lần.
- Mùa và nhiệt độ phải có trước nội dung mùa Đông và Tuyết Lĩnh.
- Thức Tỉnh phải có trước Ấn Ký, vì ô Ấn Ký làm từ nguyên liệu Boss.
- Steam P2P nên làm sớm trong M5, vì nó thay lớp kết nối mà mọi thứ khác dùng chung.

## Tiêu chí "game hoàn chỉnh" (bản nháp, chờ chốt)

1. Đủ 6 biome, 6 Linh Tuyền, 4 mùa với nhiệt độ, 4 nhân vật đều có 3 tầng Thức Tỉnh.
2. Mỗi biome có ít nhất 1 Boss, có Bí Cảnh, Nhân Quả đủ 3 ngưỡng.
3. Bốn người chơi qua Steam được 4 mùa (70 ngày game) mà không mất đồng bộ, không mất file lưu.
4. Có tiếng Việt và tiếng Anh. Có art, âm thanh và hướng dẫn chơi hoàn chỉnh.
5. Bản build Steam chạy ổn trên máy cấu hình tầm trung.

## Câu hỏi cần chủ dự án chốt

1. "Hoàn chỉnh" nghĩa là gì: lên **Early Access** (khoảng 2–3 biome, 2–3 nhân vật, rồi cập nhật dần) hay **1.0** (đủ hết nội dung GDD)?
2. Ra mắt với bao nhiêu biome và bao nhiêu nhân vật?
3. Có phát hành trên Steam không, và có cần Steam P2P ngay từ bản đầu không?
4. Mốc thời gian mong muốn (đây vẫn là câu hỏi còn mở ở GDD mục 16).
5. Art: dùng quy trình Hunyuan3D cho toàn bộ asset, hay thuê họa sĩ làm phần quan trọng (nhân vật, Boss)?
