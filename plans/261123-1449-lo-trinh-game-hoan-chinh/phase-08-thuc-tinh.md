# Giai đoạn 08: Thức Tỉnh Bản Nguyên, Cây Kỹ Năng và Ấn Ký

- **Trạng thái:** Hoàn thành
- **Phụ thuộc:** 05 (Đài Luyện Khí, Đan Thức Tỉnh 3 tầng), 06 (Tâm Ma, Nhân Quả), 07 (4 nhân vật Dị Nhân, `skill_tree_id`, `tribulation_id`)
- **Tiêu chí liên quan:** 4, 9, 12 (GDD mục 8, 9)

## Bối cảnh

GDD mục 8 định nghĩa tiến trình không dùng cảnh giới mà dùng **Thức Tỉnh Bản Nguyên** gồm 3 tầng (*Sơ Tỉnh*, *Trung Tỉnh*, *Toàn Tỉnh*). Mỗi tầng mở điểm kỹ năng cho cây nhánh loại trừ của từng nhân vật, mở thêm 1 ô Ấn Ký (tối đa 3 ô) và tăng nhẹ Khí Huyết tối đa. Nghi thức đột phá diễn ra tại `awakening_altar` với **Kiếp Nạn riêng của nhân vật, Thiên Kiếp và đợt yêu thú kéo tới cùng lúc**.

## Yêu cầu

1. **Dữ liệu kỹ năng & Ấn Ký:**
   - `SkillNodeDef` (`data/defs/skill_node_def.gd`): `id`, `tree_id`, `tier` (1..3), `branch`, `excludes` (mảng `StringName` các kỹ năng loại trừ nhau), `name_key`, `desc_key`, `effect_id`, `params`.
   - 24 file `.tres` trong `data/skills/` (4 cây × 3 tầng × 2 nhánh loại trừ nhau):
     - `tree_beast_bloodline`: `beast_t1_ferocity` ↔ `sense_t1_keensense`, `beast_t2_bloodlust` ↔ `sense_t2_tamer`, `beast_t3_apex` ↔ `sense_t3_primal_calm`.
     - `tree_devourer`: `devour_t1_gluttony` ↔ `devour_t1_purify`, `devour_t2_iron_gut` ↔ `devour_t2_harmony`, `devour_t3_soul_feast` ↔ `devour_t3_venom_strike`.
     - `tree_puppeteer`: `puppet_t1_legion` ↔ `puppet_t1_frugal`, `puppet_t2_overclock` ↔ `puppet_t2_long_ward`, `puppet_t3_steel_frame` ↔ `puppet_t3_swift_cast`.
     - `tree_yin_yang`: `yinyang_t1_shadow_stride` ↔ `yinyang_t1_wide_gate`, `yinyang_t2_phantom_blade` ↔ `yinyang_t2_serene_flux`, `yinyang_t3_eclipse` ↔ `yinyang_t3_harmony_palm`.
   - `ImprintDef` (`data/defs/imprint_def.gd`): `id`, `name_key`, `desc_key`, `item_id`, `boss_material`, `effect_id`, `params`.
   - 6 nguyên liệu Boss (`ghost_general_core` đã có + 5 mới: `flame_wolf_heart`, `iron_turtle_shell`, `thunder_roc_feather`, `frost_wyrm_scale`, `ancient_warden_core`).
   - 6 Ấn Ký (`data/imprints/*.tres`, `data/items/imprint_*.tres`, `data/recipes/imprint_*.tres` chế tại `refining_forge` với nguyên liệu Boss ×1 + `spirit_stone` ×3):
     - `imprint_ghost_general` (`no_dark_dao_drain`): đứng trong bóng tối không tụt Đạo Tâm.
     - `imprint_flame_wolf` (`fire_immunity`): miễn sát thương bỏng/nhiệt cao.
     - `imprint_iron_turtle` (`thorns_reflect`): phản 25% sát thương cận chiến.
     - `imprint_thunder_roc` (`lightning_surge`): miễn sét đánh + tăng tốc ngắn hạn khi bị sét.
     - `imprint_frost_wyrm` (`frost_immunity`): miễn cóng/chậm do lạnh.
     - `imprint_ancient_warden` (`trap_immunity`): miễn bẫy sàn cổ & giảm chậm bùn.
2. **Logic Cây Kỹ Năng & Ấn Ký (`world/simulation/world_skills.gd`):**
   - Verb `unlock_skill`: kiểm tra `skill_points >= 1`, `tier <= awakening_tier`, đúng `skill_tree_id`, chưa mở và không có kỹ năng trong `excludes` đã mở.
   - Verb `equip_imprint` / `unequip_imprint`: số ô tối đa = `mini(3, awakening_tier)`; tháo lắp tự do về túi đồ.
3. **Nghi thức Thức Tỉnh (`world/simulation/world_awakening.gd`):**
   - Verb `start_awakening`: đứng cạnh `awakening_altar` (<= 3.5 m), `awakening_tier < 3`, không có nghi thức đang chạy. Tiêu thụ lễ vật theo tầng:
     - Tầng 1: `minor_awakening_pill` ×1 + 3 Yêu Đan (`monster_core_low` hoặc `monster_core`).
     - Tầng 2: `mid_awakening_pill` ×1 + 3 `monster_core_mid`.
     - Tầng 3: `full_awakening_pill` ×1 + 3 `monster_core_high`.
   - 3 mặt trận diễn ra đồng thời qua 3 đợt:
     - **Thiên Kiếp:** gọi cảnh báo sét `WorldWeather.schedule_lightning` quanh Trận Bàn (`lightning_rod` hút sét giúp giảm tải).
     - **Kiếp Nạn riêng:** Huyết Mạch (cuồng tính dâng mạnh, hóa điên > 6s hoặc đánh đồng đội gây sát thương phản phệ); Thực Hồn (Đan Độc tăng liên tục, vượt ngưỡng chịu phản phệ nặng); Khôi Lỗi Sư (phải giữ ít nhất 1 rối chiến sống sót cuối mỗi đợt); Âm Dương Thể (Đạo Tâm dao động mạnh, trượt khỏi ranh giới cuối đợt bị sét phạt, 2 lần thất bại).
     - **Yêu thú kéo tới:** sinh đợt quái (`no_respawn = true`) lao tới quanh Trận Bàn.
   - Hoàn thành đủ 3 đợt: `awakening_tier += 1`, `skill_points += 1`, `base_max_health += 15`.
   - Thất bại (hóa Hồn Phách, rời Trận Bàn > 12 m, hoặc thua Kiếp Nạn): hủy nghi thức, mất lễ vật.
4. **HUD & Lưu:**
   - `ui/hud/awakening_panel.gd` (phím `K` và nút trên HUD): xem tầng, điểm kỹ năng, mở nhánh loại trừ, gắn/tháo Ấn Ký, theo dõi đợt nghi thức.
   - `ui/hud/hud_target.gd`: nút bắt đầu Thức Tỉnh khi chọn `awakening_altar`.
   - `SAVE_VERSION` 9 trong `SaveManager`: lưu và chuyển đổi `awakening_tier`, `skill_points`, `skills`, `imprints`, `rituals`.

## Các bước

1. Tạo `SkillNodeDef`, `ImprintDef` và toàn bộ file `.tres` trong `data/skills/`, `data/imprints/`, `data/items/`, `data/recipes/`.
2. Viết `world/simulation/world_skills.gd` và `world/simulation/world_awakening.gd`.
3. Nối vào `game_world.gd`, `state_replicator.gd`, `world_life.gd`, `world_combat.gd`, `world_temperature.gd`, `world_weather.gd`, `world_abilities.gd`, `save_manager.gd`.
4. Tạo `ui/hud/awakening_panel.gd`, nối `game_ui.gd` và `hud_target.gd`, cập nhật `localization/strings.csv`.
5. Viết test `tests/test_awakening.gd`, `tests/test_skills_and_imprints.gd`.

## Kiểm chứng

- `tests/test_skills_and_imprints.gd`: mở nhánh này thì nhánh loại trừ bị từ chối; gắn/tháo Ấn Ký tôn trọng số ô theo tầng; hiệu ứng Ấn Ký hoạt động đúng.
- `tests/test_awakening.gd`: tiêu thụ đủ lễ vật, Thiên Kiếp + đợt quái + Kiếp Nạn chạy đồng thời; sống qua 3 đợt tăng tầng và điểm kỹ năng; rời xa hoặc chết hủy nghi thức.

## Rủi ro

- Trùng lặp gói tin khi `rituals` thay đổi mỗi frame: chỉ `touch` hoặc đồng bộ chữ ký gọn trong `StateReplicator`.

## Hoàn tác

- Tắt nghi thức bằng tùy chọn `awakening: false`; mỗi kỹ năng/Ấn Ký là `.tres` độc lập.
