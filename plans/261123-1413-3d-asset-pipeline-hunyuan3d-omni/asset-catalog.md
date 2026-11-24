# Danh sách asset 3D — Hoang Giới Ký

Danh sách tổng hợp toàn bộ asset cho game hiện tại (cập nhật sau **Đợt 1**: 59 món / 63 GLB đã gắn vào gameplay).

**Ký hiệu trạng thái:**
- ✅ **Đã có (Đợt 1):** Đã có file `.glb` và đã nối vào `entities/view/model_library.gd`.
- 🔧 **Cần sửa / hoàn thiện (Đợt 2A):** Đã có GLB nhưng bị lỗi hình khối, thiếu rig hoặc thiếu socket/biến thể.
- ⬜ **Thiếu (Đợt 2B / 2C / 3 / 4):** Chưa có asset, hiện đang dùng khối tạm trong game.

---

## 0A. Danh sách cần sửa từ Đợt 1 (Đợt 2A — Làm ngay)

| id / file | Lỗi hiện tại (theo `asset-manifest.json` & PR #1) | Yêu cầu sửa |
|---|---|---|
| `weapon_spear` 🔧 | Ra hình rìu hai lưỡi | Tạo lại dáng giáo dài 1,6 m, mũi giáo đá/kim loại rõ ràng |
| `tool_axe_stone` 🔧 | Cán bị chẻ đôi | Tạo lại cán gỗ liền mạch, lưỡi đá buộc dây |
| `tool_hammer` 🔧 | Cán bị chẻ đôi | Tạo lại búa đá/gỗ cán liền |
| `tool_pickaxe_stone` 🔧 | Cán bị chẻ đôi | Tạo lại cuốc đá cán liền |
| `pill_heal` (+ 4 biến thể đan) 🔧 | Thành đĩa dẹt | Tạo lại viên đan tròn kèm lọ sứ nhỏ (`pill_base` rồi đổi màu 5 viên) |
| `armor_grass` 🔧 | Ra vòng cỏ thay vì áo | Tạo lại dáng áo giáp cỏ gấp gọn (`armor_grass_item.glb`) |
| `char_ancient_beast_blood` 🔧 | Bản tĩnh, chưa rig | Gắn rig humanoid + đủ clip (`idle`, `walk`, `run`, `attack`, `chop`, `mine`, `dig`, `pickup`, `use`, `eat`, `hit`, `death`) |
| `struct_campfire`, `struct_fire_pit` 🔧 | Chưa tách `logs_full`, `logs_low`, `ash` và `flame_socket` | Tách object con theo trạng thái nhiên liệu + empty `flame_socket` |

## 0B. Nền đất tự nhiên (Đợt 2B — Texture seamless & Phủ nền MultiMesh)

### Texture mặt đất seamless (`assets/textures/ground/<biome>/`)
Mỗi biome cần 2 bộ texture tileable 1024×1024 (`*_albedo.png`, `*_normal.png`, `*_roughness.png`), không có bóng đổ nung sẵn:

| Biome | Nền chính (`main`) | Nền phụ (`accent`) | Trạng thái |
|---|---|---|---|
| `bamboo_forest` | Đất mùn rêu xanh lục nhạt + lá trúc rụng | Đường đất mòn nâu xám + sỏi nhỏ | ⬜ Đợt 2B |
| `nether_swamp` | Bùn đen tím ẩm ướt | Rêu độc xanh xỉn + cỏ úa | ⬜ Đợt 2B |
| `crimson_volcano` | Tro núi lửa xám đen | Đá bazan nứt rạn ánh đỏ trầm | ⬜ Đợt 2B |
| `thunder_gorge` | Đá phiến xám xanh tím | Đất cháy sém + cát sỏi | ⬜ Đợt 2B |
| `frost_peaks` | Tuyết nén trắng xám xanh | Đá băng xám lạnh lộ thiên | ⬜ Đợt 2B |
| `ancient_ruins` | Đá lát cổ nứt vỡ phủ rêu | Đất cát khô xen cỏ dại | ⬜ Đợt 2B |

### Phủ nền rải `MultiMesh` (`assets/models/nature/decor/`) — **BẮT BUỘC ≤ 150 tam giác/mẫu**

| id | Tên | Biến thể | Kích thước | Tam giác tối đa | Trạng thái |
|---|---|---|---|---|---|
| `decor_grass_tuft` | Bụi cỏ thấp | `a`, `b`, `c` | 0,4 × 0,4 × 0,35 | **80** | ⬜ Đợt 2B |
| `decor_pebbles` | Cụm sỏi | `a`, `b` | 0,5 × 0,5 × 0,1 | **100** | ⬜ Đợt 2B |
| `decor_flower` | Cụm hoa dại | `red`, `purple`, `yellow` | 0,3 × 0,3 × 0,3 | **120** | ⬜ Đợt 2B |
| `decor_fern` | Bụi dương xỉ | `a`, `b` | 0,7 × 0,7 × 0,5 | **150** | ⬜ Đợt 2B |
| `decor_fallen_log` | Khúc gỗ mục nằm đất | 1 file | 2,0 × 0,5 × 0,5 | **300** | ⬜ Đợt 2B |
| `decor_mushroom_cluster` | Cụm nấm nhỏ trang trí | 1 file | 0,3 × 0,3 × 0,2 | **150** | ⬜ Đợt 2B |

---

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
| `struct_campfire` | Lửa Trại | Vòng đá + củi. Object con: `logs_full`, `logs_low`, `ash` (Godot bật tắt theo nhiên liệu). Empty `flame_socket` | 1,2 × 1,2 × 0,5 | 3000 (800 vỡ vòng đá, 23-11) | pal | P0 |
| `struct_fire_pit` | Lò Lửa (lửa trại bền) | Bếp đá xếp cao hơn. Object con như trên | 1,5 × 1,5 × 0,8 | 1200 | pal | P0 |
| `struct_crafting_table` | Bàn Chế Tác | Bàn gỗ thô, trên có rìu, dây, vài miếng gỗ | 1,4 × 0,9 × 1 | 1800 | pal | P0 |
| `struct_chest` | Rương | Object con `lid` có pivot ở bản lề để Godot mở nắp | 0,9 × 0,6 × 0,6 | 800 | pal | P0 |
| `struct_cook_pot` | Nồi Linh Thực | Nồi gốm trên kiềng đá. Object con `lid`, empty `steam_socket` | 1 × 1 × 1,1 | 1500 | 512 | P0 |
| `struct_alchemy_furnace` | Lò Đan | Lò đồng ba chân, viền vàng đồng, có cửa lò. Object con `door`, empty `fire_socket`, `smoke_socket` | 1,3 × 1,3 × 1,8 | 2500 | 512 | P0 |
| `struct_herb_field` | Ruộng Linh Thảo | Luống đất có viền gỗ. Object con: `crop_seed`, `crop_young`, `crop_grown`, `crop_mutated` (Godot bật tắt theo giai đoạn) | 2 × 2 × 0,3 (cây cao tới 0,6) | 1500 | pal | P0 |
| `struct_revive_altar` | Hồi Hồn Đài | Đài đá cổ tròn bậc thang nứt vỡ, hai cột đá nguyên khối khắc phù văn phát sáng nhẹ, rễ và rêu, bát đá ở giữa. Empty `spirit_socket` | 2,5 × 2,5 × 2,5 | 3000 | 512 | P0 |
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

## 9. Asset còn thiếu cho bản game đầy đủ (Đợt 2C, Đợt 3, Đợt 4)

### Đợt 2C — Hoàn thiện Rừng Linh Trúc (lộ rõ ngay khi vào game)

| Game ID | Tên / Mô tả | Thư mục đích | Kích thước | Trạng thái |
|---|---|---|---|---|
| `bamboo` (`bamboo_cluster`) | Bụi linh trúc (`full`, `cut`, `regrow`) — đang là khối trụ/cầu xanh! | `nature/bamboo_cluster/` | 2 × 2 × 7 | ⬜ Đợt 2C |
| `forest_pheasant` | Gà rừng linh (`idle`, `walk`, `run`, `flee`, `hit`, `death`) — xuất hiện ngay ở Rừng Linh Trúc | `creatures/creature_forest_pheasant/` | cao 0,45 | ⬜ Đợt 2C |
| `teleport_array` | Trận Pháp Truyền Tống (đĩa đá cổ khắc phù văn, có rãnh phát sáng `active`/`dormant`) | `structures/struct_teleport_array/` | 3,6 × 3,6 × 0,25 | ⬜ Đợt 2C |
| `ruin_path` | Phiến đá lát đường phế tích (nứt vỡ, rêu bám, thay ô vuông nâu dưới đất) | `nature/ruin_path/` | 1,8 × 1,8 × 0,08 | ⬜ Đợt 2C |
| `floor_trap` | Bẫy sập phế tích (tấm đá cơ quan cổ) | `nature/floor_trap/` | 1,2 × 1,2 × 0,1 | ⬜ Đợt 2C |
| `mud` | Vũng bùn lầy (dẹt, viền bùn nhão) | `nature/mud/` | 2,8 × 2,8 × 0,06 | ⬜ Đợt 2C |
| `grass` (`bush_grass`) | Bụi cỏ sợi (`full`, `picked`) | `nature/bush_grass/` | 0,8 × 0,8 × 0,8 | ⬜ Đợt 2C |
| `tree_common_a_stump`, `bush_berry_picked`, `rock_*_stage2/3` | Các biến thể sau khi chặt/hái/đập | `nature/` | theo bảng mục 1 | ⬜ Đợt 2C |

### Đợt 3 — Nhân vật, Công trình nâng cao, Khôi Lỗi, NPC & Bí Cảnh

- **Nhân vật (4 model có rig humanoid):**
  - `devourer` (Thực Hồn Nhân — áo choàng tối, mặt nạ/vết ấn tối) ⬜
  - `puppeteer` (Ngự Khí & Khôi Lỗi Sư — mang túi bùa/dây điều khiển) ⬜
  - `yin_yang` (Âm Dương Thể — áo hai tông sáng/tối, bùa Thái Cực) ⬜
  - `char_ancient_beast_blood_beastform` (Dạng Hóa Thú của Cổ Thú, cao 2 m) ⬜
- **Công trình còn thiếu (13 công trình trong `data/recipes/`):**
  - `alchemy_furnace_t2` (Lò Đan bậc 2 — lớn hơn, phù văn đồng sáng) ⬜
  - `talisman_desk` (Bàn Vẽ Phù) ⬜
  - `refining_forge` (Đài Luyện Khí / Rèn) ⬜
  - `talisman_chest` (Rương Bùa chống cháy/chống trộm) ⬜
  - `awakening_altar` (Đài Thức Tỉnh) ⬜
  - `guest_altar` (Đài Dẫn Khách) ⬜
  - `soul_lantern` (Đèn Dẫn Hồn) ⬜
  - `light_pillar` (Trụ Chiếu Sáng) ⬜
  - `lightning_rod` (Trụ Dẫn Lôi) ⬜
  - `water_array` (Trận Tụ Thủy) ⬜
  - `ice_cellar` (Hầm Băng) ⬜
  - `ice_structure` (Khối Băng chống cháy) ⬜
  - `stake` (Cọc Tiêu / Cọc Đánh Dấu) ⬜
- **Khôi Lỗi & NPC (rig humanoid đơn giản):**
  - `puppet_chop`, `puppet_mine`, `puppet_haul` (3 Khôi Lỗi gỗ/đá lao động) + `puppet_guard` (Khôi Lỗi vệ sĩ) ⬜
  - NPC: `merchant` (Thương Nhân), `enforcer` (Chấp Pháp), `evil_cultivator` (Tà Tu) ⬜
- **Bí Cảnh (`secret_realm_*`):**
  - `secret_realm_portal` (Cổng vào Bí Cảnh), `secret_realm_exit` (Cổng thoát), `realm_switch` (Trụ công tắc), `realm_chest` (Rương Bí Cảnh) ⬜

### Đợt 4 — 5 Biome còn lại, 14 Yêu thú thường, Tâm Ma & 6 Boss

- **14 Yêu thú thường + Tâm Ma (có rig & hoạt ảnh):**
  - Đầm Lầy U Minh: `spirit_leech`, `carrion_crow`, `jiangshi`, `wraith` ⬜
  - Hỏa Sơn Xích Viêm: `lava_lizard`, `fire_bird` ⬜
  - Lôi Cốc: `thunder_beast`, `stone_golem` ⬜
  - Tuyết Sơn Băng Phong: `ice_wolf` (hoặc dùng biến thể trắng của sói), `snow_bear`, `thick_fur_beast` ⬜
  - Phế Tích Cổ: `construct_beast`, `ruin_wraith` ⬜
  - Tâm Ma (phong cách mực thủy mặc): `heart_demon` ⬜
- **6 Boss Biome (kích thước lớn 2,5–4 m, có rig):**
  - `boss_ghost_general` (U Minh Quỷ Tướng) ⬜
  - `boss_flame_wolf` (Xích Viêm Hỏa Lang) ⬜
  - `boss_iron_turtle` (Huyền Thiết Nham Quy) ⬜
  - `boss_thunder_roc` (Lôi Bằng) ⬜
  - `boss_frost_wyrm` (Băng Giao) ⬜
  - `boss_ancient_warden` (Thủ Vệ Cổ Tích) ⬜
- **Tài nguyên, hang ổ & phế tích 5 biome:**
  - Cây: `rotten_tree`, `charred_tree`, `snow_pine`, `ancient_pine`, `ancient_fruit_tree`, `reed_clump` ⬜
  - Mỏ khoáng & cột đá: `cinnabar_ore`, `dark_iron_vein`, `eternal_ice_vein`, `magma_ore`, `thunder_crystal_vein`, `ice_boulder`, `sect_ore`, `seal_stone`, `carved_pillar` ⬜
  - Hang ổ & di tích: `ancient_grave`, `wraith_shrine`, `golem_pillar`, `ice_fishing_hole`, `broken_sword_pile`, `bird_nest`, `fire_bird_nest`, `crow_den`, `leech_den`, `lava_lizard_den`, `snow_bear_den`, `thick_fur_den`, `thunder_beast_den`, `construct_den` ⬜
  - Thảo dược & nấm đặc trưng: `snow_lotus_node`, `fire_lotus_node`, `glow_mushroom_node`, `ruin_mushroom_node`, `volt_moss_node`, `ancient_vine_node` ⬜

## 10. Đợt 2 — đã tạo (Omni + Paint + fit, giữ mesh Omni)

Tạo theo danh sách thực thể có trong code (`data/`, `model_library.gd`) mà chưa có model riêng. Ảnh xem trước: `art-source/previews/models_*.jpg` (không commit).

Pipeline sửa trong đợt này: `hgk_fit.py` ghi `metallicFactor = 0`, bỏ `KHR_materials_specular`, nâng sáng texture ×1,17 (Đợt 1 đã fit lại theo cùng cách; `_fix_materials` hạ albedo 1,22 → 1,05). Rig: `creature_rig.py` (4 chân, rắn), `bird_rig.py` (chim), `rigid_rig.py` (quái hình người, Khôi Lỗi).

**Yêu thú & Boss (có rig + clip)** (20): `boss_ancient_warden`, `boss_flame_wolf`, `boss_frost_wyrm`, `boss_ghost_general`, `boss_iron_turtle`, `boss_thunder_roc`, `carrion_crow`, `construct_beast`, `fire_bird`, `forest_pheasant`, `heart_demon`, `jiangshi`, `lava_lizard`, `ruin_wraith`, `snow_bear`, `spirit_leech`, `stone_golem`, `thick_fur_beast`, `thunder_beast`, `wraith`

**Tài nguyên, hang ổ, phế tích** (31): `ancient_grave`, `ancient_vine_node`, `ash_pile`, `bamboo_cluster`, `bird_nest`, `broken_sword_pile`, `carved_pillar`, `construct_den`, `crow_den`, `fire_bird_nest`, `fire_lotus_node`, `floor_trap`, `golem_pillar`, `gravel_pile`, `ice_fishing_hole`, `lava_lizard_den`, `leech_den`, `mud`, `pheasant_den`, `reed_clump`, `ruin_debris`, `rune_crystal_node`, `seal_stone`, `snow_bear_den`, `snow_lotus_node`, `snow_moss_node`, `snow_pile`, `thick_fur_den`, `thunder_beast_den`, `volt_moss_node`, `wraith_shrine`

**Công trình & Khôi Lỗi** (12): `ice_cellar`, `ice_structure`, `light_pillar`, `lightning_rod`, `puppet_chop`, `puppet_haul`, `puppet_mine`, `refining_forge`, `soul_lantern`, `stake`, `talisman_desk`, `water_array`

**Vật phẩm** (60): `ancient_gear`, `ancient_golem_core`, `ancient_vine`, `ancient_warden_core`, `ash`, `beast_cage`, `filled_beast_cage`, `broken_sword`, `charcoal`, `thunder_crystal`, `charged_thunder_crystal`, `cinnabar`, `cool_vest`, `crow_feather`, `feather`, `fire_feather`, `thunder_roc_feather`, `dark_iron_armor`, `dark_iron_ore`, `eternal_ice`, `ice_block`, `fire_egg`, `flame_wolf_heart`, `frost_rice`, `spirit_rice`, `frost_wyrm_scale`, `fur_coat`, `fur_hat`, `straw_hat`, `ghost_general_core`, `heart_demon_essence`, `hand_warmer`, `ice_fish`, `incense`, `iron_turtle_shell`, `lava_scale`, `magma_crystal`, `minor_blood_essence`, `mud_clump`, `reed`, `resin`, `ruin_shard`, `rune_crystal`, `snow_moss`, `volt_moss`, `snowball`, `wraith_essence`, `yin_soul_crystal`, `talisman_paper`, `ghost_mask_talisman`, `bind_talisman`, `imprint_flame_wolf`, `imprint_frost_wyrm`, `imprint_ghost_general`, `imprint_iron_turtle`, `imprint_thunder_roc`, `imprint_ancient_warden`, `frost_talisman`, `lightning_ward_talisman`, `true_sight_talisman`

Dùng lại model sẵn có (chỉ nối code): `bamboo`/`bamboo_tree` → `bamboo_cluster_full`, `berry_bush` → `bush_berry_ripe`, `twig_bush` → `bush_twig_full`, `puppet_guard` → `struct_puppet_chop`.

**Còn lại / cần xem thêm:** chim `carrion_crow`, `fire_bird` hơi mảnh sau rig; `forest_pheasant` dùng rig bay (chưa có clip đi bộ/flee); boss chưa có clip riêng ngoài bộ thủ tục; biến thể giai đoạn (gốc cây, bụi đã hái, đá vỡ), decor MultiMesh ≤150 tam giác, texture nền (Đợt 2B), nhân vật/NPC Đợt 3 vẫn chưa làm. Toàn bộ model giữ mesh Omni ~40k tam giác — cần LOD/giảm mặt trước khi tối ưu hiệu năng.

## Tổng hợp tiến độ hiện tại

| Nhóm | Đã có (Đợt 1) | Cần sửa (Đợt 2A) | Thiếu (Đợt 2B–4) |
|---|---|---|---|
| Thiên nhiên + hang ổ | 9 | 0 | ~36 (+ biến thể giai đoạn) |
| Nền đất (texture + decor MultiMesh) | 0 | 0 | 12 bộ texture + 6 nhóm `decor_*` |
| Vật phẩm, công cụ, thức ăn, đan | 42 | 10 (6 món + 4 biến thể đan) | ~3–5 (túi ngủ, giáo hắc thiết, giáp cao...) |
| Công trình & Bí Cảnh | 8 | 2 (lửa trại, lò lửa tách socket) | 18 (13 công trình + 4 Bí Cảnh + `teleport_array`) |
| Nhân vật, Khôi Lỗi, NPC | 1 (tĩnh) | 1 (rig `char_ancient_beast_blood`) | 11 (3 nhân vật + Hóa Thú + 4 Khôi Lỗi + 3 NPC) |
| Yêu thú & Boss | 3 (có rig) | 0 | 21 (14 yêu thú + Tâm Ma + 6 Boss) |
