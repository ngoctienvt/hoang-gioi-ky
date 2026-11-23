# Giai đoạn 06: Tâm Ma và Nhân Quả

- **Trạng thái:** Chưa làm
- **Phụ thuộc:** 04 (yêu thú, khung hiệu ứng), 05 (Đài Dẫn Khách, Định Thần Đan, Rương bùa)
- **Tiêu chí liên quan:** 5, 9, 12

## Bối cảnh

GDD 7.1, 7.2, 12. Hiện chỉ có Đạo Tâm tụt trong tối và "cuồng tính" của Huyết Mạch. Chưa có Tâm Ma, chưa có Nhân Quả, chưa có NPC. Giai đoạn này **đứng trước Nhân vật** (khác bảng gốc) vì cái giá của Âm Dương Thể là Tâm Ma.

## Yêu cầu

### Tâm Ma (GDD 7.2)

1. Đạo Tâm dưới 30: Tâm Ma bắt đầu sinh quanh người chơi đó (tối đa 2 con một người, thêm 1 con dưới 15). Đạo Tâm trên 40 thì Tâm Ma tan.
2. Tâm Ma là yêu thú loại `heart_demon` (tập tính `heart_demon` trong `behaviors/`), **chỉ người chơi đó thấy và bị đánh**; người khác không thấy (server gửi thực thể này chỉ cho peer chủ). Đánh chết rơi **Tâm Ma Tinh** (+Đạo Tâm nhẹ khi dùng).
3. **Dấu hiệu bắt buộc:** viền màn hình nhòe mực (shader `ink_vignette.gdshader` theo mức Đạo Tâm, dùng lại `vignette.gdshader` làm nền), âm thì thầm (`world_audio.gd`, âm tạo bằng code như hiện tại), Tâm Ma vẽ khác hẳn quái thường: khối màu mực đen có viền trắng nhòe, không dùng bảng màu biome.
4. Định Thần Đan xua Tâm Ma đang có.
5. Đạo Tâm thấp (dưới 30) cũng **thấy linh thể và ẩn họa** (U Linh, bẫy sàn Di Tích hiện rõ) theo GDD 7.1.

### Nhân Quả (GDD 12)

1. `state.karma = {"sin": 0, "fate": 0}` (Nghiệp, Duyên), chung cả nhóm, 0–120.
2. **Tăng Nghiệp:** giết linh thú hiền (thỏ, trĩ, thú lông dày, thằn lằn nham khi chưa bị nó đánh), đào node có ấn ký Tông Môn (node `sect_ore` mới ở Di Tích và Hỏa Sơn), phá cấm chế (node `seal_stone` ở Di Tích), dùng cấm thuật (chiêu đánh dấu `forbidden` ở 07). **Tăng Duyên:** trả lễ Cổ Đàn (node `altar` mới ở mỗi biome, đặt lễ vật bất kỳ có thẻ `Linh`), giúp tán tu (hoàn thành nhờ việc), thả linh thú (dùng **Lồng bắt thú** mới rồi thả), trồng linh thụ (trồng cây từ Linh Quả). Số điểm mỗi hành động khai báo trong `data/karma/karma_rules.tres`.
3. **Giảm dần:** mỗi ngày mỗi thanh −2.
4. **Ngưỡng 30/60/100:** khi thanh vượt ngưỡng (lần đầu từ dưới lên, hoặc mỗi 3 ngày khi vẫn ở trên), rút **một** sự kiện từ nhóm tương ứng theo trọng số; sự kiện xảy ra thì trừ điểm của thanh (`cost` khai báo trong sự kiện, mặc định 15). Cả hai thanh từ 60: rút từ nhóm lai.
5. **Sự kiện là dữ liệu:** `KarmaEventDef` (`data/defs/karma_event_def.gd`): id, thanh, ngưỡng, trọng số, `cost`, `kind` (`spawn_npc`, `spawn_hostiles`, `steal_chest`, `open_secret_realm`, `grant_recipe`, `tame_beast`), tham số. Mỗi `kind` một hàm ngắn trong `world/simulation/world_karma_events.gd`.
6. **Bảng sự kiện tối thiểu** (đúng GDD 12.2, mỗi ô một sự kiện):

| Ngưỡng | Nghiệp | Duyên |
|---|---|---|
| 30 | Thương nhân chợ đen (bán cấm phẩm: Quy Tức Đan, Quỷ Diện, công thức cấm) · Oán linh quấy rối đêm (2–3 linh thể tới Sơn Môn) | Tán tu nhờ việc (đòi 3 món ngẫu nhiên, đưa đủ thì thưởng Linh Thạch và Yêu Đan) · Kẻ ăn xin trộm đồ (lấy 1–3 món trong một rương thường, Rương bùa không bị) |
| 60 | Đội Chấp Pháp tuần tra (3 Chấp Pháp đánh người chơi) · Tà tu mời hợp tác (mở khóa 1 công thức cấm trong Thiên Thư) | Linh thú quy thuận (1 con theo người chơi, đánh giúp 1 ngày) **hoặc** Cổng Bí Cảnh mở sớm (nối 09) · Tin đồn bảo vật (đám tán tu thù địch kéo tới) |
| 100 | Lệnh truy nã: Chấp Pháp tinh nhuệ, Tâm Ma sinh ở ngưỡng Đạo Tâm 50 trong 1 ngày | Khí vận quá vượng: tà tu cướp khí vận, thắng thì rơi báu vật lớn (Yêu Đan cao + nguyên liệu Ấn Ký ngẫu nhiên) |
| Cả hai cao | Kẻ nửa chính nửa tà: NPC trung lập đổi 1 nguyên liệu Boss lấy nhiều Yêu Đan | |

7. **NPC và thế lực:** thực thể `npc` với `faction` = `merchant`, `wanderer`, `enforcer`, `evil_cultivator`, `beggar`. Thương nhân: tương tác mở bảng mua bán (trả bằng Linh Thạch), rời đi sau 1 ngày đêm. Thế lực thù địch dùng tập tính `pack_hunter` có sẵn.
8. **Đài Dẫn Khách** (dựng ở 05): đốt 3 Linh Thạch + hương (cỏ khô + nhựa) mời thương nhân hoặc tán tu ghé 1 ngày đêm (GDD 12.4). Không tốn điểm Nhân Quả.
9. **Hiển thị:** HUD có hai thanh, số và vạch 30/60/100. Trên Sơn Môn (vị trí trung bình các công trình) có đám mây: mây lành vàng nhạt khi Duyên cao hơn, mây đen khi Nghiệp cao hơn, độ dày theo giá trị.
10. **Lưu:** `state.karma`, lịch sử sự kiện gần nhất, NPC đang có, Tâm Ma (không lưu, sinh lại). `SAVE_VERSION` 7.

## Các bước

1. Tâm Ma: tập tính, lọc gửi theo peer chủ trong replicator, shader viền mực, âm thì thầm, hình khối riêng.
2. Linh thể và ẩn họa hiện theo Đạo Tâm.
3. `world/simulation/world_karma.gd` (cộng, giảm, ngưỡng, rút sự kiện) và `world_karma_events.gd`.
4. `KarmaEventDef` + 11 sự kiện `.tres` trong `data/karma/`.
5. NPC, bảng mua bán (`ui/hud/trade_panel.gd`), nhờ việc của tán tu (`ui/hud/request_panel.gd`).
6. Node mới: `sect_ore`, `seal_stone`, `altar` (Cổ Đàn); Lồng bắt thú.
7. Đài Dẫn Khách; HUD thanh Nhân Quả; mây trên Sơn Môn.

## Kiểm chứng

- `tests/test_heart_demon.gd`: Đạo Tâm 25 sinh Tâm Ma, 45 thì tan; Tâm Ma của người A không có trong patch gửi người B; Định Thần Đan xua.
- `tests/test_karma.gd`: giết thỏ tăng Nghiệp; trả lễ Cổ Đàn tăng Duyên; giảm 2 mỗi ngày; vượt 30 rút đúng 1 sự kiện và trừ điểm; cả hai 60 rút nhóm lai; cùng seed rút cùng sự kiện.
- `tests/test_karma_events.gd`: mỗi `kind` chạy được (thương nhân xuất hiện và rời sau 1 ngày; ăn xin không lấy được từ Rương bùa; tán tu thưởng khi đưa đủ).

## Rủi ro

- Lọc thực thể theo peer chủ là trường hợp đặc biệt trong replicator; thêm trường `owner_peer` chung để dùng lại (Khôi Lỗi hộ thân ở 07, linh thú quy thuận).
- Bảng mua bán là UI mới lớn nhất từ đầu tới giờ; giữ đơn giản (danh sách, giá, nút Mua).

## Hoàn tác

`options.karma = false` khi tạo thế giới tắt rút sự kiện (dùng để test và dò lỗi).
