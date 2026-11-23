# Giai đoạn 07: Bốn nhân vật và màn chọn nhân vật

- **Trạng thái:** Hoàn thành
- **Phụ thuộc:** 05 (Khôi Lỗi, bùa, Đan Độc theo ngưỡng), 06 (Tâm Ma, chiêu cấm thuật cộng Nghiệp)
- **Tiêu chí liên quan:** 3, 9, 12

## Bối cảnh

GDD 9, 9.1. Hiện chỉ có Huyết Mạch Cổ Thú, năng lực (`sense`, `beast`) và cuồng tính ghi thẳng trong `world_life.gd`. Bảng chỉ số nền gom ở 01.

## Yêu cầu

1. **`CharacterDef`** (`data/defs/character_def.gd`) + 4 file `.tres` trong `data/characters/`: id, khóa tên/mô tả, chỉ số nền (Khí Huyết tối đa, tốc độ, tốc hồi, ngưỡng Đan Độc), danh sách chiêu (`AbilityDef`), luật đặc thù (`trait`), id cây kỹ năng (dùng ở 08), id Kiếp Nạn (dùng ở 08).
2. **`AbilityDef`** (`data/defs/ability_def.gd`): id, khóa tên, cooldown, chi phí theo GDD 9.1 (`stamina`, `poison`, `dao`, `health`, hoặc vật phẩm `item:count`), cờ `forbidden` (cộng Nghiệp), hiệu ứng. Mỗi chiêu có logic riêng nằm trong `world/simulation/abilities/<id>.gd`.
3. **Chuyển Huyết Mạch Cổ Thú sang dữ liệu** (Thú Giác, Hóa Thú, cuồng tính khi đói/Đạo Tâm thấp, mưa bão làm cuồng nhanh từ 03, chu kỳ trăng: đêm thứ 7 mỗi tuần là trăng tròn, cuồng tính dâng nhanh gấp đôi). Test cũ phải vẫn qua.
4. **Thực Hồn Nhân:**
   - Chiêu **Nuốt**: dùng trực tiếp Yêu Đan, tinh hoa quái (Tinh Huyết, Âm Hồn Tinh, Tâm Ma Tinh...), dị thảo (Hỏa Liên, Tuyết Liên, Âm Hồn Thảo). Mỗi thứ cho hiệu ứng tạm thời theo thẻ hệ (Hỏa: kháng lạnh, Băng: kháng nóng, Âm: thấy linh thể, Thú: +sát thương, Linh: hồi nhanh) và hồi Khí Huyết. Tăng Đan Độc.
   - **Ngưỡng Đan Độc cao hơn** (150 so với 100).
   - **Cái giá:** nuốt hai hệ xung khắc trong 60 giây (Hỏa–Băng, Âm–Linh) thì **xung đột thuộc tính**: mất Khí Huyết và Đạo Tâm. Vượt ngưỡng thì phản phệ gấp đôi người thường.
5. **Ngự Khí & Khôi Lỗi Sư:**
   - Chế Khôi Lỗi, bùa, trận tốn ít nguyên liệu hơn: mọi công thức nhóm Khôi Lỗi/Bùa/Trận giảm 1 nguyên liệu thường (tối thiểu 1), tỉ lệ thành công bùa +15%.
   - Chiêu **Triệu Rối Chiến**: tốn 2 Linh Thạch, triệu 1 rối chiến đấu (thực thể `puppet` task `guard`, `owner_peer`) theo chủ, đánh yêu thú gần, tồn tại 2 phút, tối đa 2 con.
   - Chiêu **Điều Rối**: chỉ định mục tiêu cho rối chiến từ xa (15 m).
   - **Cái giá:** Khí Huyết tối đa 110, tốc hồi máu −50%, tay không sát thương −50%.
6. **Âm Dương Thể:**
   - **Ngưỡng ranh giới** Đạo Tâm 35–65. Trong ngưỡng: nhìn thấy ẩn họa và linh thể như Đạo Tâm thấp mà **không** sinh Tâm Ma; mở chiêu dị biệt.
   - Chiêu **Lướt Bóng**: dịch 6 m, chỉ dùng được ở chỗ tối, tốn 8 Đạo Tâm (cấm thuật, cộng Nghiệp nhẹ).
   - Chiêu **Âm Dương Chưởng**: đòn tầm gần gây sát thương theo độ lệch Đạo Tâm so với 50.
   - **Cái giá:** trượt khỏi ngưỡng (dưới 35 hoặc trên 65) thì Tâm Ma sinh **ngay** (dùng luật 06 với ngưỡng riêng).
7. **Chọn nhân vật khi vào thế giới:** sau khi kết nối và đăng ký tên, client hiện màn chọn 4 nhân vật (tên, năng lực, cái giá). Gửi `choose_character` lên host; host chỉ nhận khi người chơi chưa có nhân vật. Người chơi cũ vào lại bằng đúng tên giữ nhân vật đã chọn. Cho phép nhiều người cùng chọn một nhân vật (GDD 8.2).
8. **HUD:** nút chiêu theo nhân vật (phím Q, F, R), thanh cooldown, chỉ báo riêng (cuồng tính, ngưỡng ranh giới, số rối).
9. **Lưu:** `player.character`, trạng thái chiêu. `SAVE_VERSION` 8, chuyển đổi gán Huyết Mạch Cổ Thú cho người chơi cũ.

## Các bước

1. `CharacterDef`, `AbilityDef`, bảng điều phối chiêu `world/simulation/world_abilities.gd` (thay `life.ability`).
2. Chuyển Huyết Mạch sang dữ liệu; tách cuồng tính ra `world/simulation/traits/beast_rage.gd`.
3. Thực Hồn Nhân (`abilities/devour.gd`, `traits/devourer_conflict.gd`).
4. Khôi Lỗi Sư (`abilities/summon_puppet.gd`, `abilities/command_puppet.gd`, giảm nguyên liệu trong kiểm tra công thức).
5. Âm Dương Thể (`abilities/shadow_step.gd`, `abilities/yin_yang_palm.gd`, `traits/boundary_dao.gd`).
6. Màn chọn nhân vật `ui/menu/character_select.gd`, verb `choose_character`.
7. Hình khối người chơi khác màu theo nhân vật.

## Kiểm chứng

- `tests/test_character_select.gd`: chọn được 1 lần; chọn lại bị từ chối; vào lại giữ nhân vật.
- `tests/test_devourer.gd`: nuốt Yêu Đan cho hiệu ứng và tăng Đan Độc; nuốt Hỏa rồi Băng trong 60 giây thì mất máu; ngưỡng Đan Độc 150.
- `tests/test_puppeteer.gd`: Triệu Rối tốn 2 Linh Thạch, tối đa 2; công thức Khôi Lỗi giảm nguyên liệu; Khí Huyết tối đa 110.
- `tests/test_yin_yang.gd`: Đạo Tâm 50 thấy linh thể, không sinh Tâm Ma; 30 sinh Tâm Ma ngay; Lướt Bóng không dùng được chỗ sáng.
- Test Huyết Mạch cũ vẫn qua.

## Rủi ro

- Lướt Bóng dịch vị trí người chơi trên host trong khi `network_avatar` giữ vị trí vật lý: phải đặt vị trí avatar cùng lúc (giống dịch chuyển ở 02).

## Hoàn tác

Mỗi nhân vật là dữ liệu + file chiêu riêng; ẩn khỏi màn chọn bằng cờ `selectable` trong `.tres`.
