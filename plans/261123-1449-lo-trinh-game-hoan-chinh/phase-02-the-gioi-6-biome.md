# Giai đoạn 02: Thế giới 6 biome

- **Trạng thái:** Chưa làm
- **Phụ thuộc:** 01 (chunk, chỉ mục uid, `map_size`)
- **Tiêu chí liên quan:** 1, 9, 10, 12

## Bối cảnh

GDD mục 4 và 5. Hiện `world_seed.gd` đặt cứng 4 vùng con của một biome Rừng trên 80×80 m, có 2 suối Linh Tuyền cùng loại. Loại node lấy theo `kind` chuỗi và `world_rules.gd`.

## Yêu cầu

1. **Bố cục vùng theo seed:** bản đồ mặc định 288×288 m (12×12 chunk). Chia thành lưới 3×2 ô vùng, mỗi ô là một biome; seed xáo vị trí 6 biome, giữ Rừng Linh Trúc luôn kề điểm xuất phát (người chơi mới dễ sống). Biên giữa các vùng có dải chuyển tiếp 8 m và đường đá cổ (dải node `ruin_path` không chặn đi lại).
2. **Mảnh đặt sẵn (set piece):** Resource mới `BiomeDef` (`data/defs/biome_def.gd`) và `SetPieceDef` (`data/defs/set_piece_def.gd`). `SetPieceDef` = danh sách `{kind, offset, jitter}` + bán kính. `BiomeDef` = id, khóa tên, màu nền, danh sách set piece bắt buộc (5 lớp), set piece tùy chọn kèm trọng số, mật độ, loại Linh Tuyền, danh sách hang yêu thú. Sinh vùng: đặt hết set piece bắt buộc trước, rồi rải set piece tùy chọn tới đủ mật độ, không chồng lấn (kiểm tra khoảng cách qua chunk).
3. **Đủ 5 lớp tài nguyên mỗi biome** (thức ăn, cây gỗ, đá/quặng, vật liệu lặt vặt, hang yêu thú; hang có thể rỗng tới giai đoạn 04). Nội dung tối thiểu theo bảng dưới.
4. **6 Linh Tuyền:** node `spring` có trường `water_type` (`thanh_moc`, `u_minh`, `xich_viem`, `loi_tri`, `huyen_bang`, `co_van`). Múc nước ra vật phẩm bình nước riêng cho từng loại (`spirit_water_<type>`). Hiệu ứng tôi luyện làm ở giai đoạn 05; ở giai đoạn này chỉ cần múc, tưới, ngâm/uống đúng bảng GDD mục 5 với hiệu ứng ngắn hạn đơn giản.
5. **Cổ Truyền Tống Trận:** mỗi biome một trận ở gần tâm vùng. Trận ở trạng thái `dormant` cho tới khi có người chơi đứng lên lần đầu (kích hoạt). Tương tác với trận đã kích hoạt mở danh sách các trận khác đã kích hoạt; chọn một thì host dịch chuyển người chơi đó. Tốn 1 Linh Thạch mỗi lần (đơn giản nhất).
6. **Biome tại vị trí:** `world.biome_at(position)` tra theo ô vùng. Người chơi có trường `biome` cập nhật mỗi giây; vào biome mới thì client hiện tên biome lớn kiểu thư pháp (GDD 1.1) qua `tr()`.
7. **Môi trường biome** chỉ phần không cần mùa: sương độc Đầm Lầy (tụt Đạo Tâm), bùn chậm (giảm tốc 30% trên node `mud`), bẫy sàn Di Tích (node `floor_trap` gây sát thương khi giẫm). Nóng/rét quanh năm và sét làm ở giai đoạn 03.
8. **Nhìn:** mỗi biome một màu nền đất và bảng màu khối riêng trong `entity_meshes.gd` (đọc từ `BiomeDef`), theo quy tắc 80/20 của GDD 1.1.
9. **Lưu:** thêm `state.regions` (bố cục 6 ô), `water_type` trên spring, trạng thái trận truyền tống. Tăng `SAVE_VERSION` lên 3, chuyển đổi 2→3 gán bố cục mặc định cho thế giới cũ.

## Nội dung tối thiểu

| Biome | Thức ăn | Cây gỗ | Đá/quặng | Lặt vặt | Hang (yêu thú ở 04) |
|---|---|---|---|---|---|
| Rừng Linh Trúc (có sẵn) | bụi linh quả, nấm trắng, củ hoang | linh trúc, thông | tảng đá, đá Linh Thạch | cỏ, cành, đá lửa | thỏ, sói, khỉ |
| U Minh Đầm Lầy | nấm dạ quang, rễ thủy sinh, Âm Hồn Thảo | cây mục (gỗ ẩm, nhựa), lau sậy | đá rêu, quặng Chu Sa | bùn, sậy | đỉa, quạ, mộ cổ |
| Xích Viêm Hỏa Sơn | quả hỏa bụi, Hỏa Liên, ổ trứng dị điểu | cây cháy xém (than) | bazan, Huyền Thiết Tinh, Nham Tinh | tro, đá lửa | thằn lằn nham, chim lửa |
| Lôi Trì Thạch Cốc | rêu điện quang | tùng cổ thụ (gỗ bền) | thạch anh, Lôi Tinh Thạch, cổ kiếm gãy | sỏi | linh thú Lôi, thạch khôi lỗi |
| Hàn Băng Tuyết Lĩnh | rêu tuyết, Tuyết Liên, hố băng câu cá | tùng tuyết | băng khối, Vạn Năm Huyền Băng | tuyết | băng lang, gấu tuyết |
| Hoang Cổ Di Tích | quả dại cổ thụ, nấm tàn tích | dây leo cổ | gạch đá chạm khắc, Tinh Thể Cổ Văn | mảnh phế tích | cơ quan thú, linh thể |

Mỗi node mới là một `ResourceNodeDef` `.tres` trong `data/nodes/`, mỗi vật phẩm mới là `ItemDef` `.tres` trong `data/items/` có thẻ nấu/luyện (GDD 6.2) để giai đoạn 05 dùng. Công cụ cần: đá thường dùng Cuốc đá lửa; Huyền Thiết Tinh, Lôi Tinh Thạch, Vạn Năm Huyền Băng cần **Cuốc Linh Thạch** (công thức bậc 2 mới).

## Các bước

1. Viết `BiomeDef`, `SetPieceDef` và 6 file biome `.tres`, set piece `.tres` trong `data/biomes/`, `data/set_pieces/`.
2. Viết `world/simulation/world_layout.gd` (chia 6 ô theo seed) và `world/simulation/world_biome_generator.gd` (đặt set piece). `world_seed.gd` chỉ còn gọi hai file này.
3. Thêm node, vật phẩm, công thức Cuốc Linh Thạch, khóa dịch.
4. Viết `world/simulation/world_teleport.gd` (kích hoạt, danh sách, dịch chuyển). Thêm verb `teleport` vào bảng điều phối của `game_world.gd`.
5. Spring nhiều loại; múc/tưới/uống theo `water_type`.
6. Môi trường biome không theo mùa (sương độc, bùn, bẫy sàn).
7. Hiển thị tên biome, màu theo biome.
8. Chạy lại `tests/test_bandwidth.gd` trên bản đồ 6 biome thật (thay thế giới giả). Ghi số đo.

## Kiểm chứng

- `tests/test_world_layout.gd`: cùng seed ra cùng bố cục; seed khác ra bố cục khác ít nhất một vị trí; mỗi biome có đủ 5 lớp (đếm node theo thẻ lớp); mỗi biome đúng 1 spring đúng loại và 1 trận truyền tống; Rừng kề ô xuất phát.
- `tests/test_teleport.gd`: trận chưa kích hoạt không dùng được; thiếu Linh Thạch thì từ chối; dịch chuyển đúng vị trí.
- `tests/test_spring_types.gd`: múc mỗi loại ra đúng vật phẩm; uống ra đúng hiệu ứng.
- `tests/test_bandwidth.gd` vẫn đạt ngưỡng ở giai đoạn 01.

## Rủi ro

- Số thực thể tăng nhiều (ước tính 4.000–6.000 node). Nếu `step` của tài nguyên lặp qua tất cả mỗi khung hình thì chậm: chỉ cập nhật node đang mọc lại (danh sách riêng `regrowing`).
- Bố cục 3×2 cố định hơi lặp. Chấp nhận ở bản này, ghi vào câu hỏi mở.

## Hoàn tác

Bố cục và generator là file mới; giữ `world_seed.gd` cũ trong git để quay lại nếu cần.
