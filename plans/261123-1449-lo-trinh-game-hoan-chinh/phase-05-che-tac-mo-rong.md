# Giai đoạn 05: Chế tác mở rộng (đan, bùa, Khôi Lỗi, Pháp Trận, công trình, tôi vũ khí)

- **Trạng thái:** Chưa làm
- **Phụ thuộc:** 02 (nguyên liệu 6 biome, 6 loại Linh Thủy), 03 (bùa ẩm, nhiệt độ cho đan kháng môi trường), 04 (Yêu Đan, nguyên liệu rơi)
- **Tiêu chí liên quan:** 7, 8, 9, 12

## Bối cảnh

GDD 5, 6.3–6.8. Hiện có: Lò Đan crockpot với `TagRecipeDef` (4 đan), Nồi (5 món), tôi vũ khí một loại (`vitality_hits`), ruộng Linh Thảo, Rương, Hồi Hồn Đài. `world_structures.gd` 123 dòng, `world_spring.gd` 93 dòng: phải tách trước khi thêm.

Giai đoạn này **đứng trước Nhân vật** (khác bảng gốc) vì Khôi Lỗi Sư cần Khôi Lỗi có sẵn.

## Yêu cầu

### Đan dược, 7 nhóm (GDD 6.5)

Mỗi đan một `TagRecipeDef` + `ItemDef`, hiệu ứng khai báo trong `ItemDef.effects` (dạng `{tên hiệu ứng: [độ lớn, thời gian]}`) thay vì code riêng từng viên.

| Nhóm | Đan tối thiểu | Hiệu ứng |
|---|---|---|
| Cấp cứu | Hồi Huyết Đan (đã có) | hồi Khí Huyết ngay |
| Kháng môi trường | Ôn Dương Đan, Thanh Lương Đan, Tị Độc Đan, Tị Thủy Đan | khóa thân nhiệt về 50 / miễn sương độc / miễn tụt Đạo Tâm do mưa, 1 ngày |
| Đạo Tâm | Định Thần Đan (đã có `calm_pill`) | +Đạo Tâm, xua Tâm Ma (dùng ở 06) |
| Năng lực tạm thời | Dạ Thị Đan (đã có), Khinh Thân Đan, Quy Tức Đan | thấy trong tối / +30% tốc chạy / yêu thú không phát hiện |
| Khắc chế Boss | Phá Chướng Đan | thấy và đánh được U Minh Quỷ Tướng trong sương. Nguyên liệu: **Quỷ Tướng Hồn Tinh** (vật phẩm khai báo ở đây, rơi từ Boss ở giai đoạn 09) |
| Thức Tỉnh | Sơ Tỉnh Đan, Trung Tỉnh Đan, Toàn Tỉnh Đan | lễ vật nghi thức (dùng ở 08) |
| Hồi sinh | Hoàn Hồn Đan (đã có) | hồi sinh Hồn Phách |

- **Dung môi hợp hệ:** ô dung môi nhận 6 loại Linh Thủy, cộng tỉ lệ thành công cho nhóm đan đúng bảng GDD 5 (Thanh Mộc → trị liệu, U Minh → Đạo Tâm, Xích Viêm → kháng lạnh, Lôi Trì → tốc độ, Huyền Băng → kháng nóng, Cổ Văn → mọi loại một ít).
- **Bậc lò:** Lò Đan bậc 1 (có) và Lò Đan bậc 2 (thêm Huyền Thiết Tinh), bậc 2 cộng 15% tỉ lệ.
- **Đan Độc:** đã có `poison`; thêm ngưỡng theo nhân vật (đọc từ bảng chỉ số nền ở 01), debuff khi vượt (buồn nôn: không ăn được 20 giây, tụt Đạo Tâm, chậm hồi), món Linh Thực giảm Đan Độc (Canh Thanh Độc).

### Bàn Vẽ Phù và bùa (GDD 6.6)

- Công trình Bàn Vẽ Phù. Công thức cố định (`RecipeDef` có `success`), cần giấy bùa (từ sậy hoặc tre) + Chu Sa + nguyên liệu hệ.
- Bùa tối thiểu: **Định Thân Phù** (choáng mục tiêu 3 giây), **Hàn Băng Phù** (làm chậm và ngắt chiêu, dùng cho Hỏa Lang ở 09), **Khai Nhãn Phù** (thấy linh thể 1 phút), **Quỷ Diện** (yêu thú không phát hiện 1 phút), **Phù Tránh Lôi** (sét bỏ qua người dùng 30 giây).
- Ném bùa: verb `throw_talisman` có mục tiêu hoặc vị trí trong 8 m.
- **Rương bùa:** chống cháy, khỉ không trộm, bùa bên trong không ẩm (luật ẩm từ 03).

### Khôi Lỗi và Pháp Trận (GDD 6.8)

- **Đài Luyện Khí:** công trình rèn binh khí bậc 2, giáp, lắp Khôi Lỗi, làm Ấn Ký (Ấn Ký làm ở 08).
- **Cọc khoanh vùng:** đặt cọc tạo vùng tròn 8 m.
- **Khôi Lỗi Lao Động** (`world/simulation/world_puppets.gd` + `puppet_tasks.gd`): thực thể mới `puppet` có `task` = `haul` (nhặt đồ rơi trong vùng, chở về rương gần cọc nhất), `chop` (chặt cây trong vùng), `mine` (đào đá trong vùng). Ăn 1 Linh Thạch mỗi nửa ngày, hết thì đứng yên. Đi chậm (2 m/s). Có máu, yêu thú tấn công được, hỏng thì rơi một phần nguyên liệu. Không vào nghi thức, không đánh Boss.
- **Thủy Dẫn Trận:** đặt cạnh ruộng, nạp bình Linh Thủy; tự tưới ruộng trong 6 m mỗi ngày; nạp loại nước nào thì cây ra biến thể của loại đó. Chặn tự bốc cháy mùa Hạ trong 8 m (luật từ 03).

### Công trình Sơn Môn (GDD 6.7)

Đủ danh sách: Bếp lửa (có), Nồi Linh Thực (có), Rương bùa, Ruộng Linh Thảo (có), **Đèn Dẫn Hồn** (nguồn sáng đêm không tốn lửa, xua linh thể, ép U Minh Quỷ Tướng hiện hình ở 09), **Trụ Chiếu Sáng** (sáng bán kính lớn, ăn Linh Thạch), Lò Đan, Bàn Vẽ Phù, Đài Luyện Khí, **Trận Bàn Thức Tỉnh** (chỉ dựng ở đây, nghi thức ở 08), Hồi Hồn Đài (có), **Đài Dẫn Khách** (dựng ở đây, sự kiện mời khách ở 06).

### Tôi vũ khí bằng 6 loại Linh Thủy (GDD 5, tiêu chí 8)

`world/simulation/world_tempering.gd`. Vũ khí giữ `temper = {type, hits}`. Nhúng nước mới thay hiệu ứng cũ (không cộng dồn), mỗi lần 20 đòn.

| Nước | Hiệu ứng khi đánh trúng |
|---|---|
| Thanh Mộc | Sinh Cơ: hồi 2 Khí Huyết |
| U Minh | Phá Hồn: đánh trúng linh thể, U Linh, Quỷ Tướng |
| Xích Viêm | Thiêu Đốt: hiệu ứng `burn` 3 giây |
| Lôi Trì | Lôi Kích: 20% `stun` 1 giây |
| Huyền Băng | Hàn Băng: `slow` 40% trong 3 giây |
| Cổ Văn | Tẩy Luyện: xóa hiệu ứng tôi đang có (không thêm gì) |

### Biến thể cây theo nước tưới (GDD 5)

Ruộng trồng **Linh Mễ** (hạt mới) ngoài Linh Thảo. Tưới Huyền Băng ra Hàn Mễ (ăn mát người), Xích Viêm: không tưới được, Thanh Mộc ra nhanh và có tỉ lệ Linh Quả biến dị, U Minh ra Âm Hồn Thảo, Lôi Trì lớn ngay nhưng 30% héo chết, Cổ Văn ra ngẫu nhiên một loại hiếm. Mỗi biến thể là `ItemDef` có thẻ riêng cho nồi và lò.

### Lưu

Thực thể `puppet`, `stake`, trường `temper`, trạng thái Thủy Dẫn Trận, công trình mới. `SAVE_VERSION` 6, chuyển đổi `vitality_hits` cũ thành `temper = {type: "thanh_moc"}`.

## Các bước

1. Tách `world_structures.gd` (đặt/nhiên liệu/lò/nồi) và `world_spring.gd` (múc/tưới/trồng) trước khi thêm.
2. Khung `ItemDef.effects` + `world/simulation/world_effects.gd` áp hiệu ứng thời gian cho người chơi và yêu thú.
3. Đan, dung môi, bậc lò, Đan Độc theo ngưỡng.
4. Bàn Vẽ Phù, giấy bùa, bùa, ném bùa, Rương bùa.
5. Đài Luyện Khí, cọc, Khôi Lỗi, Thủy Dẫn Trận.
6. Đèn Dẫn Hồn, Trụ Chiếu Sáng, Trận Bàn Thức Tỉnh, Đài Dẫn Khách.
7. Tôi vũ khí 6 loại; biến thể cây.
8. Thiên Thư hiển thị đủ nhóm mới (thêm tab Bùa, Khôi Lỗi).

## Kiểm chứng

- `tests/test_elixir_groups.gd`: mỗi nhóm có ít nhất 1 đan chế được; dung môi đúng hệ cộng tỉ lệ; vượt ngưỡng Đan Độc ra debuff.
- `tests/test_talismans.gd`: thiếu Chu Sa thì từ chối; Định Thân Phù làm yêu thú đứng yên; bùa trong Rương bùa không ẩm.
- `tests/test_puppets.gd`: Khôi Lỗi `haul` đưa đồ rơi vào rương; `chop` chặt cây trong vùng, không ra ngoài vùng; hết Linh Thạch thì dừng.
- `tests/test_tempering.gd`: mỗi loại nước ra đúng hiệu ứng; nhúng loại khác thì thay; Cổ Văn xóa; hết 20 đòn thì mất.
- `tests/test_crop_variants.gd`: tưới mỗi loại ra đúng biến thể.

## Rủi ro

- Khôi Lỗi tìm đường: không có navmesh trên host. Dùng đi thẳng kèm né vật cản đơn giản (đổi hướng 45° khi kẹt quá 1 giây). Ghi vào báo cáo nếu kẹt nhiều.
- Nhiều vật phẩm mới làm Thiên Thư dài. Thêm tìm kiếm là ngoài phạm vi; chỉ thêm tab.

## Hoàn tác

Mỗi nhóm (đan, bùa, Khôi Lỗi, tôi luyện) là file riêng, gỡ được độc lập.
