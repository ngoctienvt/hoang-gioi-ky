# Danh sách asset 3D — Hoang Giới Ký

Danh sách lấy từ [kế hoạch demo](../261123-1353-demo-hoang-gioi-ky/plan.md) (giai đoạn 03–10) và [GDD](../../docs/game-design-document.md).

**Mức ưu tiên:**
- **P0:** demo bắt buộc phải có.
- **P1:** demo cần nhưng tạm dùng khối đơn giản được.
- **P2:** sau demo (vertical slice). Chỉ làm khi xong P0 và P1.

**Cột "Kích thước":** dài (X) × rộng (Z) × cao (Y), đơn vị mét, sai lệch cho phép khoảng 15%. **Tam giác:** ngân sách tối đa. **Tex:** cỡ texture (`pal` = dùng `assets/palette.png` chung).

**Tên file:** `assets/models/<thư mục>/<id>/<id>_<biến thể hoặc giai đoạn>.glb`. Ví dụ `assets/models/nature/rock_boulder/rock_boulder_stage1.glb`.

---

## 1. Thiên nhiên: điểm tài nguyên (`nature/`) — xem phase-02

| id | Tên | Biến thể / giai đoạn (mỗi cái một file GLB) | Kích thước | Tam giác | Tex | Ưu tiên |
|---|---|---|---|---|---|---|
| `tree_common_a`, `tree_common_b`, `tree_common_c` | Cây gỗ thường (3 dáng) | `standing` (đứng), `stump` (gốc sau khi đổ), `sapling` (cây non mới trồng, cao 0,6 m) | 3 × 3 × 6 | 3500 / 400 / 400 | pal | P0 (dáng a), P1 (b, c) |
| `tree_autumn_red` | Cây tán đỏ mùa Thu | `standing`, `stump` | 3 × 3 × 5,5 | 3500 | pal | P1 |
| `tree_autumn_purple` | Cây tán tím | `standing`, `stump` | 3 × 3 × 5 | 3500 | pal | P1 |
| `bamboo_cluster` | Bụi linh trúc | `full` (6–9 cây), `cut` (gốc trúc), `regrow` (măng non) | 2 × 2 × 7 | 2500 / 300 / 300 | pal | P0 |
| `rock_boulder` | Tảng đá | `stage1` (nguyên), `stage2` (nứt, mất 1/3), `stage3` (vụn còn ít) | 1,4 × 1,2 × 1,1 | 800 mỗi giai đoạn | pal | P0 |
| `rock_spirit_ore` | Tảng Linh Thạch | `stage1`, `stage2`, `stage3`; tinh thể Linh Thạch là **object con tách riêng, tên `crystal`** (để Godot cho phát sáng) | 1,4 × 1,2 × 1,2 | 1000 mỗi giai đoạn | pal | P0 |
| `bush_berry` | Bụi linh quả | `ripe` (có quả, quả là object con `berries`), `picked` (không quả) | 1,2 × 1,2 × 1 | 1500 | pal | P0 |
| `bush_grass` | Bụi cỏ sợi | `full`, `picked` | 0,8 × 0,8 × 0,8 | 600 | pal | P0 |
| `bush_twig` | Bụi cành khô | `full`, `picked` | 0,9 × 0,9 × 1 | 700 | pal | P0 |
| `herb_spirit_wild` | Linh Thảo mọc dại | một file | 0,4 × 0,4 × 0,4 | 400 | pal | P0 |
| `spring_thanh_moc` | Thanh Mộc Tuyền | một file: vòng đá bao quanh, ở giữa để trống (mặt nước do Godot làm), có rêu và vài cây nhỏ | 3 × 3 × 0,6 | 2000 | pal | P0 |

## 2. Thiên nhiên: trang trí, không tương tác (`nature/decor/`) — xem phase-02

| id | Tên | Biến thể | Kích thước | Tam giác | Tex | Ưu tiên |
|---|---|---|---|---|---|---|
| `decor_grass_tuft` | Búi cỏ (rải hàng nghìn cái bằng MultiMesh) | `a`, `b`, `c` | 0,4 × 0,4 × 0,35 | **80** | pal | P0 |
| `decor_flower` | Cụm hoa dại | `red`, `purple`, `yellow` | 0,3 × 0,3 × 0,3 | 120 | pal | P1 |
| `decor_pebbles` | Cụm sỏi | `a`, `b` | 0,5 × 0,5 × 0,1 | 120 | pal | P1 |
| `decor_mushroom_cluster` | Cụm nấm trang trí | một file | 0,3 × 0,3 × 0,2 | 200 | pal | P1 |
| `decor_fallen_log` | Khúc gỗ mục nằm đất | một file | 2 × 0,5 × 0,5 | 600 | pal | P1 |
| `decor_fern` | Bụi dương xỉ | `a`, `b` | 0,7 × 0,7 × 0,5 | 300 | pal | P1 |

## 3. Hang ổ yêu thú (`nature/`) — xem phase-02

| id | Tên | Ghi chú | Kích thước | Tam giác | Tex | Ưu tiên |
|---|---|---|---|---|---|---|
| `den_rabbit_burrow` | Hang thỏ linh | Ụ đất có lỗ hang, cỏ xung quanh | 1,2 × 1,2 × 0,4 | 600 | pal | P0 |
| `den_wolf` | Ổ sói | Khe đá lớn + xương + cỏ lót | 4 × 3 × 2 | 2500 | pal | P0 |
| `den_monkey_nest` | Ổ khỉ linh | Tổ cành lá trên một gốc cây thấp, chỗ chất đồ trộm | 2 × 2 × 2,5 | 1800 | pal | P0 |

## 4. Vật phẩm: nguyên liệu (`items/`) — xem phase-03

Vật phẩm nằm dưới đất trong game và cũng dùng để render icon. Pivot tâm đáy. Cùng phải dễ nhận ra khi to bằng lòng bàn tay trên màn hình.

| id | Tên | Kích thước (cao/dài) | Tam giác | Tex | Ưu tiên |
|---|---|---|---|---|---|
| `item_twigs` | Cành khô (bó nhỏ) | dài 0,5 | 300 | pal | P0 |
| `item_grass_fiber` | Cỏ sợi (bó) | dài 0,4 | 300 | pal | P0 |
| `item_flint` | Đá lửa | 0,12 | 150 | pal | P0 |
| `item_log` | Gỗ (khúc) | dài 0,7 | 300 | pal | P0 |
| `item_bamboo` | Linh trúc (đoạn) | dài 0,8 | 200 | pal | P0 |
| `item_stone` | Đá | 0,2 | 150 | pal | P0 |
| `item_spirit_stone` | Linh Thạch | 0,15 | 200 | pal | P0 |
| `item_spirit_berry` | Quả linh (chùm) | 0,12 | 300 | pal | P0 |
| `item_white_mushroom` | Nấm trắng | 0,12 | 200 | pal | P0 |
| `item_wild_tuber` | Củ hoang | 0,15 | 200 | pal | P0 |
| `item_pine_cone` | Quả thông (hạt cây) | 0,1 | 200 | pal | P0 |
| `item_rope` | Dây thừng (cuộn) | 0,2 | 400 | pal | P0 |
| `item_meat_small` | Thịt nhỏ (sống) | 0,15 | 200 | 256 | P0 |
| `item_meat` | Thịt (sống) | 0,25 | 250 | 256 | P0 |
| `item_pelt` | Da lông (gấp) | 0,4 | 300 | 256 | P0 |
| `item_wolf_tooth` | Răng sói | 0,08 | 100 | pal | P0 |
| `item_monkey_fur` | Lông khỉ (nhúm) | 0,15 | 200 | pal | P0 |
| `item_spirit_herb` | Linh Thảo (đã hái) | 0,2 | 200 | pal | P0 |
| `item_herb_seed` | Hạt Linh Thảo (túi nhỏ) | 0,1 | 200 | pal | P0 |
| `item_beast_core_small` | Yêu Đan nhỏ (viên ngọc đỏ tím mờ) | 0,06 | 150 | 256 | P0 |
| `item_mutated_fruit` | Linh Quả biến dị (to, phát sáng nhẹ) | 0,18 | 300 | 256 | P0 |

## 5. Vật phẩm: công cụ, vũ khí, đồ mặc (`items/`) — xem phase-03

| id | Tên | Kích thước (dài) | Tam giác | Tex | Ưu tiên |
|---|---|---|---|---|---|
| `tool_axe_stone` | Rìu đá | 0,6 | 500 | pal | P0 |
| `tool_pickaxe_stone` | Cuốc đá | 0,65 | 500 | pal | P0 |
| `tool_shovel` | Xẻng | 0,9 | 500 | pal | P0 |
| `tool_hammer` | Búa (đập công trình) | 0,55 | 500 | pal | P0 |
| `weapon_spear` | Giáo | 1,6 | 500 | pal | P0 |
| `tool_torch` | Đuốc; đầu đuốc có điểm rỗng tên `flame_socket` (empty object) để Godot gắn lửa | 0,55 | 300 | pal | P0 |
| `tool_water_flask` | Bình Đựng Nước (bầu hồ lô có nút). Hai file: `empty`, `filled` (nút buộc dải vải xanh linh khí) | 0,25 | 400 | pal | P0 |
| `armor_grass` | Giáp cỏ: hai file. `item` (gấp lại, nằm đất) và `worn` (mặc lên nhân vật, skin theo rig nhân vật, xem phase-05) | — | 1200 | pal | P0 |
| `bedroll_grass` | Túi ngủ cỏ (cuộn) | 0,6 | 400 | pal | P1 |

## 6. Vật phẩm: thức ăn & đan dược (`items/`) — xem phase-03

| id | Tên | Ghi chú | Tam giác | Tex | Ưu tiên |
|---|---|---|---|---|---|
| `food_berry_roasted` | Quả nướng | Quả linh xém vàng nâu | 300 | pal | P0 |
| `food_meat_roasted` | Thịt nướng | Xiên que | 300 | 256 | P0 |
| `food_mushroom_roasted` | Nấm nướng | Xiên que | 300 | pal | P0 |
| `food_berry_soup` | Canh Linh Quả | Bát gốm | 500 | 256 | P0 |
| `food_meat_mushroom_stew` | Thịt Hầm Nấm | Bát gốm | 500 | 256 | P0 |
| `food_steamed_tuber` | Củ Hấp | Đĩa lá chuối | 400 | 256 | P0 |
| `food_spirit_feast` | Linh Thực Tổng Hợp | Bát to, nhiều màu | 600 | 256 | P0 |
| `food_burnt` | Món Cháy | Đống đen cháy trong bát | 400 | 256 | P0 |
| `food_dish_6` | Món thứ 6 (tên chốt sau ở dữ liệu) | Bát gốm, khác màu | 500 | 256 | P1 |
| `pill_heal` | Hồi Huyết Đan | Viên tròn đỏ, kèm lọ sứ nhỏ | 200 | 256 | P0 |
| `pill_calm_mind` | Định Thần Đan | Viên xanh lam | 200 | 256 | P0 |
| `pill_night_sight` | Dạ Thị Đan | Viên vàng | 200 | 256 | P0 |
| `pill_revive` | Hoàn Hồn Đan | Viên trắng ngọc, có vân linh khí | 200 | 256 | P0 |
| `pill_waste` | Phế Đan | Viên xám nứt, xỉn màu | 150 | 256 | P0 |

> Các viên đan dùng **chung một mesh**, chỉ khác màu texture. Làm 1 mesh `pill_base` rồi xuất 5 file khác màu là được.

## 7. Công trình Sơn Môn (`structures/`) — xem phase-04

| id | Tên | Trạng thái (mỗi cái một file, hoặc object con bật tắt) | Kích thước | Tam giác | Tex | Ưu tiên |
|---|---|---|---|---|---|---|
| `struct_campfire` | Lửa Trại | Vòng đá + củi. Object con: `logs_full`, `logs_low`, `ash` (Godot bật tắt theo nhiên liệu). Empty `flame_socket` | 1,2 × 1,2 × 0,5 | 800 | pal | P0 |
| `struct_fire_pit` | Lò Lửa (lửa trại bền) | Bếp đá xếp cao hơn. Object con như trên | 1,5 × 1,5 × 0,8 | 1200 | pal | P0 |
| `struct_crafting_table` | Bàn Chế Tác | Bàn gỗ thô, trên có rìu, dây, vài miếng gỗ | 1,4 × 0,9 × 1 | 1800 | pal | P0 |
| `struct_chest` | Rương | Object con `lid` có pivot ở bản lề để Godot mở nắp | 0,9 × 0,6 × 0,6 | 800 | pal | P0 |
| `struct_cook_pot` | Nồi Linh Thực | Nồi gốm trên kiềng đá. Object con `lid`, empty `steam_socket` | 1 × 1 × 1,1 | 1500 | 512 | P0 |
| `struct_alchemy_furnace` | Lò Đan | Lò đồng ba chân, viền vàng đồng, có cửa lò. Object con `door`, empty `fire_socket`, `smoke_socket` | 1,3 × 1,3 × 1,8 | 2500 | 512 | P0 |
| `struct_herb_field` | Ruộng Linh Thảo | Luống đất có viền gỗ. Object con: `crop_seed`, `crop_young`, `crop_grown`, `crop_mutated` (Godot bật tắt theo giai đoạn) | 2 × 2 × 0,3 (cây cao tới 0,6) | 1500 | pal | P0 |
| `struct_revive_altar` | Hồi Hồn Đài | Đài đá tròn bậc thang, cột sơn đỏ cổ phong, lư hương. Empty `spirit_socket` | 2,5 × 2,5 × 2,5 | 3000 | 512 | P0 |
| `struct_placement_ghost` | — | Không cần làm. Godot tự dựng bóng mờ từ mesh công trình | — | — | — | — |

## 8. Nhân vật & yêu thú (`characters/`, `creatures/`) — xem phase-05

| id | Tên | Kích thước | Tam giác | Tex | Rig | Hoạt ảnh bắt buộc | Ưu tiên |
|---|---|---|---|---|---|---|---|
| `char_ancient_beast_blood` | Huyết Mạch Cổ Thú (người xuyên không, áo vải thô, có nét thú: tai nhọn, vệt vằn trên tay) | cao 1,7 | 9000 | 1024 | Người (humanoid) | `idle`, `walk`, `run`, `attack`, `chop`, `mine`, `dig`, `pickup`, `use`, `eat`, `hit`, `death`, `beast_transform` | P0 |
| `char_ancient_beast_blood_beastform` | Hóa Thú (cùng nhân vật, to hơn, lưng gù, móng vuốt, lông) | cao 2 | 9000 | 1024 | Dùng chung rig nhân vật nếu được | `idle`, `walk`, `run`, `attack`, `hit` | P1 |
| `char_ghost` | Hồn Phách | — | — | — | — | Không cần model: Godot dùng lại mesh nhân vật với shader bán trong suốt | — |
| `creature_spirit_rabbit` | Thỏ linh (lông trắng kem, tai dài, đuôi phát sáng nhẹ) | dài 0,45, cao 0,35 | 2500 | 512 | Thú 4 chân | `idle`, `hop`, `run`, `eat`, `hit`, `death` | P0 |
| `creature_forest_wolf` | Sói rừng (lông xám nâu, dáng gầy, mắt vàng) | dài 1,4, cao vai 0,8 | 5000 | 1024 | Thú 4 chân | `idle`, `walk`, `run`, `attack`, `howl`, `sleep`, `hit`, `death` | P0 |
| `creature_spirit_monkey` | Khỉ linh (lông vàng nâu, đuôi dài, mặt tinh nghịch) | cao 0,9 khi đứng | 4000 | 512 | Nửa người (đi 4 chân và 2 chân) | `idle`, `walk`, `run`, `pickup`, `carry`, `flee`, `hit`, `death` | P0 |

## 9. Backlog sau demo (P2) — chưa làm

- **Nhân vật:** Thực Hồn Nhân; Ngự Khí & Khôi Lỗi Sư; Âm Dương Thể.
- **Biome U Minh Đầm Lầy:** cây mục, lau sậy, đá rêu, mỏ Chu Sa, nấm dạ quang, mộ cổ, U Minh Âm Tuyền; đỉa linh, quạ, Cương Thi, U Linh.
- **Boss:** U Minh Quỷ Tướng, Xích Viêm Hỏa Lang, Huyền Thiết Nham Quy.
- **Công trình:** Bàn Vẽ Phù, Đài Luyện Khí, Trận Bàn Thức Tỉnh, Đèn Dẫn Hồn, Trụ Chiếu Sáng, Trụ Dẫn Lôi, Rương bùa, Đài Dẫn Khách, Cổ Đàn, Khôi Lỗi Lao Động.
- **Kiến trúc cổ phong cho Sơn Môn:** tường, cổng tam quan, mái cong, đèn lồng (làm thành bộ module ghép được).
- **Tâm Ma:** cần phong cách riêng khác hẳn quái thường (nét mực thủy mặc), chốt art direction riêng trước khi làm.

## Tổng số (để ước lượng thời gian)

| Nhóm | P0 | P1 |
|---|---|---|
| Thiên nhiên + hang ổ | 15 id (khoảng 30 file theo giai đoạn) | 9 id |
| Vật phẩm nguyên liệu | 21 | 0 |
| Công cụ, vũ khí, đồ mặc | 8 | 1 |
| Thức ăn, đan | 13 | 1 |
| Công trình | 8 | 0 |
| Nhân vật, yêu thú | 4 (có rig) | 1 |
