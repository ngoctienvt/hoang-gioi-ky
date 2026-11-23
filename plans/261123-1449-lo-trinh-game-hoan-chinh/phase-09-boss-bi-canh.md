# Giai đoạn 09: Sáu Boss theo Biome và Bí Cảnh

- **Trạng thái:** Hoàn thành
- **Phụ thuộc:** 02 (6 biome), 04 (tập tính yêu thú), 05 (Đèn Dẫn Hồn, Thủy Dẫn Trận, bùa chú, tôi vũ khí), 08 (nguyên liệu Boss dùng cho Ấn Ký)
- **Tiêu chí liên quan:** 6, 9, 12 (GDD mục 10, 12.4)

## Bối cảnh

GDD mục 10 và 12.4 quy định thế giới có Boss theo từng biome với cơ chế chiến đấu đòi hỏi khắc chế (không phải đứng chém tay không) và **Bí Cảnh** mở theo thiên tượng hoặc sự kiện Nhân Quả (vào được, giải đố/hạ thủ vệ, lấy kho báu, và ra được).

## Yêu cầu

1. **Sáu Boss theo 6 biome (`data/creatures/boss_*.tres`):**
   - `boss_ghost_general` (U Minh Đầm Lầy): miễn sát thương vật lý khi ẩn sương nếu thiếu `soul_lantern` đang sáng trong 8 m, vũ khí tôi `u_minh`, hoặc hiệu ứng `pierce_mist`. Rơi `ghost_general_core`.
   - `boss_flame_wolf` (Xích Viêm Hỏa Sơn): gồng mưa lửa đốt nóng khu vực; bị ngắt chiêu và choáng khi trúng `frost_talisman` hoặc đòn tôi `huyen_bang` (`water_array` gần đó giảm 60% sát thương lửa). Rơi `flame_wolf_heart`.
   - `boss_iron_turtle` (Rừng Linh Trúc): mai cứng giảm 70% sát thương và phản đòn tầm xa; húc trúng `lightning_rod` hoặc tảng đá trong 2.5 m bị nứt giáp (`shell_cracked`) nhận 150% sát thương. Rơi `iron_turtle_shell`.
   - `boss_thunder_roc` (Lôi Trì Thạch Cốc): gọi sét đánh theo vùng; khi `lightning_rod` gần đó hấp thụ đủ 2 tia sét sẽ bị kéo xuống đất (`grounded`), nhận 130% sát thương. Rơi `thunder_roc_feather`.
   - `boss_frost_wyrm` (Hàn Băng Tuyết Lĩnh): tỏa hàn khí làm chậm & đóng băng; đứng gần `campfire`/`firepit` đang cháy hoặc đánh bằng vũ khí tôi `xich_viem` làm tan giáp băng (`frost_melted`). Rơi `frost_wyrm_scale`.
   - `boss_ancient_warden` (Hoang Cổ Di Tích): khiên cổ văn giảm 80% sát thương; bị phá khiên bởi vũ khí tôi `loi_tri` hoặc `bind_talisman`. Rơi `ancient_warden_core`.
2. **Triệu hồi tại Cổ Đàn (`world/simulation/world_bosses.gd`):**
   - Verb `summon_boss` tại `altar` (<= 3.5 m): tiêu thụ 3 Yêu Đan bất kỳ, sinh Boss tương ứng với biome của Cổ Đàn đó (`no_respawn = true`, `is_boss = true`). Mỗi biome chỉ có tối đa 1 Boss sống cùng lúc.
3. **Bí Cảnh (`world/simulation/world_secret_realm.gd`):**
   - Cổng `secret_realm_portal` tự mở vào đêm trăng tròn hoặc khi bão sét (hoặc qua sự kiện Duyên 60).
   - Verb `enter_secret_realm`: lưu `realm_return_pos`, đánh dấu `in_secret_realm = true`, đưa người chơi vào đấu trường Bí Cảnh (`REALM_ORIGIN = [1200, 0, 1200]`, bán kính 16 m) gồm cổng ra (`secret_realm_exit`), 3 trụ phù văn (`realm_switch`), 3 thủ vệ (`construct_beast`, `ruin_wraith`), và rương kho báu (`realm_chest`).
   - Verb `activate_switch`: kích hoạt đủ 3 trụ thì mở khóa `realm_chest`.
   - Verb `claim_vault`: nhận vật phẩm hiếm (`monster_core_high`, `ancient_golem_core`, `spirit_stone`).
   - Verb `exit_secret_realm`: đưa người chơi về lại `realm_return_pos`. Khi cổng hết hạn, tự động đẩy toàn bộ người chơi đang ở trong Bí Cảnh ra ngoài an toàn.
4. **Hiển thị, HUD & Lưu:**
   - Thanh máu Boss (`ui/hud/hud_boss.gd`) hiện khi có Boss sống trong 25 m.
   - Hình khối Boss & các thực thể Bí Cảnh trong `entity_meshes.gd`.
   - `game_session.gd` và `world_creatures.gd` tôn trọng biên đấu trường Bí Cảnh khi thực thể có `in_secret_realm = true`.
   - `SAVE_VERSION` 10 trong `SaveManager`.

## Các bước

1. Tạo 6 `CreatureDef` Boss trong `data/creatures/`.
2. Viết `world/simulation/world_bosses.gd`, `world/simulation/behaviors/boss_mechanics.gd`, `world/simulation/world_secret_realm.gd`.
3. Nối vào `game_world.gd`, `world_combat.gd`, `world_talismans.gd`, `world_creatures.gd`, `world_life.gd`, `game_session.gd`, `state_replicator.gd`, `save_manager.gd`.
4. Thêm `ui/hud/hud_boss.gd`, nút thao tác trong `hud_target.gd`, hình khối trong `entity_meshes.gd`, khóa dịch trong `localization/strings.csv`.
5. Viết test `tests/test_bosses.gd`, `tests/test_secret_realm.gd`.

## Kiểm chứng

- `tests/test_bosses.gd`: triệu hồi tại Cổ Đàn tốn 3 Yêu Đan; đủ 6 cơ chế Boss và khắc chế hoạt động; chết rơi nguyên liệu đặc trưng.
- `tests/test_secret_realm.gd`: vào Bí Cảnh, kích hoạt 3 trụ mở khóa rương, nhận thưởng, thoát ra đúng vị trí cũ; hết hạn tự đẩy ra.

## Rủi ro

- `NetworkAvatar` kẹp vị trí theo `map_limit`: phải bỏ qua kẹp biên bản đồ chính khi `player.in_secret_realm == true` và dùng biên Bí Cảnh.

## Hoàn tác

- Tắt mở cổng tự nhiên bằng cờ `secret_realm: false`; mỗi Boss là file `.tres` độc lập.
