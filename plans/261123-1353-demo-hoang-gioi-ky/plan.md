---
title: Demo Hoang Giới Ký
status: in-progress
priority: P1
effort: large
branch: main
tags: [godot, survival, coop]
created: 2026-11-23
---

# Kế hoạch Demo — Hoang Giới Ký

- **Trạng thái:** Đang làm — giai đoạn 02–09 đã triển khai, chờ chủ dự án chơi thử; giai đoạn 10 còn build Windows và LAN 10 ngày
- **Ngày lập:** 2026-11-23
- **Nguồn thiết kế:** [docs/game-design-document.md](../../docs/game-design-document.md)
- **Đội làm:** Chủ dự án + AI
- **Engine:** Godot 4.7.2 bản **.NET** (bắt buộc cho plugin Godot-MCP), game viết bằng GDScript. Mạng: một người chơi làm host (ENet, kết nối IP/LAN)
- **Công cụ AI:** Godot-MCP của IvanMurzak (`godot-cli`, server `ai-game-developer` chạy local). Plugin cần project có C# solution, nhưng code game vẫn là GDScript

## Mục tiêu demo

Một nhóm 1–4 người vào cùng thế giới qua host, sống sót qua mùa Thu ở biome Rừng Linh Trúc với đầy đủ vòng sinh tồn kiểu DST: lượm tài nguyên, chế rìu và cuốc, chặt cây, đào khoáng, dựng lửa trại và Sơn Môn, nấu ăn, săn và chống yêu thú, chịu ngày đêm. Thêm vào đó là các nét riêng của game: nhân vật Huyết Mạch Cổ Thú, Lò Đan kiểu crockpot, Thanh Mộc Tuyền và hồi sinh bằng Hồn Phách.

## Tiêu chí hoàn thành (Acceptance criteria)

1. Host tạo thế giới, 1–3 người khác vào qua IP. Mọi người thấy nhau di chuyển và thao tác mượt trên LAN.
2. Bắt đầu tay trắng, lượm cành, cỏ, đá lửa, chế được Rìu, Cuốc, Đuốc, Lửa Trại, Bàn Chế Tác. Chặt cây ra gỗ, đào đá ra đá và Linh Thạch. Công cụ có độ bền và hỏng.
3. Chu kỳ ngày 8 phút với tỉ lệ mùa Thu. Đêm không có ánh sáng thì bị Hắc Ám tấn công.
4. Ba chỉ số Khí Huyết, Thể Lực, Đạo Tâm hoạt động và hiển thị trên HUD.
5. Nướng đồ trên lửa trại. Nồi Linh Thực ra món theo công thức thẻ. Lò Đan ra đan với tỉ lệ thành công, thất bại ra Phế Đan, có Đan Độc.
6. Ba loài yêu thú (thỏ linh, sói, khỉ linh) có tập tính riêng. Đánh được, rơi nguyên liệu thô.
7. Huyết Mạch Cổ Thú dùng được Hóa Thú (tốn Thể Lực, có cooldown) và Thú Giác.
8. Thanh Mộc Tuyền: múc nước, tưới ruộng ra biến thể, tôi vũ khí ra hiệu ứng Sinh Cơ.
9. Chết thì rơi đồ, thành Hồn Phách, hồi sinh bằng Hoàn Hồn Đan hoặc Hồi Hồn Đài. Cả nhóm chết thì Reset hoặc Chơi tiếp theo tùy chọn thế giới.
10. Host lưu và tải lại thế giới. Toàn bộ chữ hiển thị là tiếng Việt qua khóa dịch.
11. Các bài test logic (kho đồ, chế tác, khớp công thức, chỉ số) chạy được ở chế độ headless và đều qua.

## Không làm trong demo (Non-goals)

Biome thứ 2 trở đi, mùa Đông/Xuân/Hạ và nhiệt độ, Tâm Ma, Thức Tỉnh và Thiên Kiếp, Ấn Ký, Nhân Quả, Boss, Bí Cảnh, Khôi Lỗi, Bàn Vẽ Phù, nhân vật thứ 2, hư hỏng thực phẩm, Steam, xoay camera, art hoàn chỉnh (demo dùng khối đơn giản tô màu theo art direction ở GDD mục 1.1, có sương, bloom và ánh sáng ngày đêm).

## Các giai đoạn

| # | Giai đoạn | Phụ thuộc | Trạng thái |
|---|---|---|---|
| 01 | [Cài đặt & khung dự án](phase-01-project-setup.md) | — | Xong (2026-11-23) |
| 02 | [Mạng, nhân vật điều khiển & camera](phase-02-networking-player-camera.md) | 01 | Đã triển khai; chờ chủ dự án kiểm tra |
| 03 | [Vật phẩm, kho đồ & đồ dưới đất](phase-03-items-inventory.md) | 02 | Đã triển khai; chờ chủ dự án kiểm tra |
| 04 | [Thế giới & điểm tài nguyên](phase-04-world-resource-nodes.md) | 03 | Đã triển khai; chờ chủ dự án kiểm tra |
| 05 | [Chế tác & công trình](phase-05-crafting-structures.md) | 04 | Đã triển khai; chờ chủ dự án kiểm tra |
| 06 | [Thời gian, ánh sáng & chỉ số sinh tồn](phase-06-time-light-survival-stats.md) | 05 | Đã triển khai; chờ chủ dự án kiểm tra |
| 07 | [Thức ăn & nấu nướng](phase-07-food-cooking.md) | 06 | Đã triển khai; chờ chủ dự án kiểm tra |
| 08 | [Yêu thú & chiến đấu](phase-08-creatures-combat.md) | 06 | Đã triển khai; chờ chủ dự án kiểm tra |
| 09 | [Nhân vật, Lò Đan & Linh Tuyền](phase-09-character-alchemy-spring.md) | 07, 08 | Đã triển khai; chờ chủ dự án kiểm tra |
| 10 | [Chết, lưu game & hoàn thiện demo](phase-10-death-save-polish.md) | 09 | Đã có chết/lưu/âm thanh/tùy chọn; còn build & LAN 10 ngày |

## Quyết định kiến trúc chung

- **Host có quyền quyết định (host-authoritative).** Client chỉ gửi yêu cầu thao tác (`request_*` RPC) lên host. Host kiểm tra hợp lệ, đổi trạng thái thế giới rồi đồng bộ xuống. Không tin dữ liệu từ client.
- **Dữ liệu tách khỏi code.** Vật phẩm, công thức, điểm tài nguyên, yêu thú định nghĩa bằng Resource (`.tres`) trong `data/`. Thêm nội dung không sửa code.
- **Component nhỏ, tái dùng:** `HealthComponent`, `InventoryComponent`, `InteractableComponent`, `WorkableComponent` (chịu nhát rìu/cuốc), `DurabilityComponent`.
- **Autoload:** `NetworkManager`, `GameClock`, `ItemDB`, `RecipeDB`, `SaveManager`, `EventBus`.
- **File code dưới 200 dòng**, tên file snake_case theo chuẩn Godot.
- **Kiểm thử:** GUT cho logic thuần (kho đồ, khớp công thức, chỉ số, đồng hồ). Gameplay và mạng thì chạy thử thủ công với 2 cửa sổ game.
- **Git:** khởi tạo repo ở giai đoạn 01, commit theo từng giai đoạn.

## Rủi ro chính

- **Đồng bộ mạng** là phần dễ vỡ nhất. Phải có từ giai đoạn 02, mọi tính năng sau đều thử với 2 cửa sổ.
- **Phạm vi phình to.** Bám sát danh sách Non-goals, ý tưởng mới ghi vào GDD chứ không làm thêm trong demo.

## Tiến độ triển khai — 2026-11-23

Đã đồng bộ cả 10 giai đoạn theo mã nguồn. Không đánh dấu hoàn tất acceptance chỉ từ việc có code. Các phase giữ nguyên danh sách yêu cầu gốc; mục tiến độ cuối mỗi file chỉ rõ mã thực tế và việc chủ dự án kiểm tra.

Kiến trúc hiện dùng `InventoryComponent`, `SurvivalStats` và các module `world/simulation/`; các trách nhiệm máu/khai thác/tương tác/độ bền chưa được tách thành đủ các lớp component đã dự kiến. Giao diện demo lấy cảm hứng DST và dùng lại `world/style_test/style_test.tscn` qua `entities/demo/demo_style.gd`.

Còn: chơi thử gameplay từng giai đoạn, cân chỉnh số liệu, xuất Windows và LAN/IP 2–4 người trong 10 ngày Thu. Theo yêu cầu mới, AI dừng chạy kiểm thử; chủ dự án thực hiện các kiểm tra trong [báo cáo triển khai](../reports/implementation-261123-1425-demo.md).
