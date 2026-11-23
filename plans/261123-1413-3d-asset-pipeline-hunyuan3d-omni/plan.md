# Kế hoạch tạo asset 3D — Hoang Giới Ký (Hunyuan3D-Omni chạy local)

- **Trạng thái:** Đang thực hiện — Đã xong **Đợt 1** (59 món / 63 GLB, đã gắn vào gameplay chính), chuẩn bị **Đợt 2–4**
- **Ngày lập:** 2026-11-23 (cập nhật: 2026-11-23)
- **Người thực hiện:** máy của anh chủ dự án, chạy Hunyuan3D-Omni local, có AI (Claude) hỗ trợ
- **Người duyệt:** AI (Claude) bên máy tạo asset tự đánh giá, tự duyệt và tự làm lại nếu chưa đạt (không cần dừng chờ chủ dự án duyệt từng món/từng đợt)
- **Nguồn thiết kế:** [GDD mục 1.1 Art direction](../../docs/game-design-document.md), [Kế hoạch demo](../261123-1353-demo-hoang-gioi-ky/plan.md)
- **Danh sách asset đầy đủ:** [asset-catalog.md](asset-catalog.md)

> File này viết cho AI bên máy tạo asset đọc. Đọc hết file này và `asset-catalog.md` trước khi tạo asset đầu tiên.

## Mục tiêu

Tạo đủ model 3D cho bản demo (biome Rừng Linh Trúc & Đồng Cỏ, mùa Thu, 1 nhân vật, 3 loài yêu thú), cùng một phong cách, đúng tỉ lệ, đúng quy ước để thả thẳng vào Godot mà không phải sửa tay. Sau demo, dùng lại đúng quy trình này cho vertical slice.

## Tiêu chí hoàn thành

1. Mọi asset có mức ưu tiên **P0** trong `asset-catalog.md` đã có file `.glb` trong `assets/models/`, đúng tên, đúng thư mục.
2. Mỗi asset qua toàn bộ checklist kỹ thuật ở [phase-06](phase-06-godot-import-and-qa.md): tỉ lệ mét, pivot, hướng mặt, số tam giác, một material, texture đúng cỡ.
3. Mọi asset đều đã qua bước tự đánh giá bằng ảnh xem trước của Claude (`approved_by: "claude-auto"`); các món lỗi hình khối (như giáo thành rìu, cán chẻ đôi, đan dẹt, giáp thành vòng) phải tự tạo lại cho đạt trước khi mở PR.
4. Nhân vật và 3 loài yêu thú có rig và đủ hoạt ảnh bắt buộc.
5. `assets/asset-manifest.json` ghi đủ nguồn gốc từng asset (công cụ, phiên bản, ảnh đầu vào, ai duyệt), dùng để khai báo nội dung AI khi lên Steam.
6. Mở project trong Godot, toàn bộ GLB import không lỗi, đặt cạnh nhân vật cao 1,7 m trông đúng tỉ lệ dưới góc camera game.

## Không làm (Non-goals)

- Icon 2D của vật phẩm: phía Godot sẽ render icon từ chính file GLB. Vì vậy model cần đẹp khi nhìn nghiêng 3/4 từ trên xuống.
- Nước sông/suối, hiệu ứng (lửa, khói, đom đóm, linh khí, Hắc Ám, sét): làm bằng shader và particle trong Godot.
- Hình va chạm (collision): phía Godot tự dựng khối đơn giản.

## Chiến lược làm nền đất tự nhiên (3 lớp)

Không dùng mesh Omni 40k tam giác cho mặt đất hay cỏ rải. Để nền đất trông tự nhiên và ăn nhập với model 3D, chia thành 3 lớp:

1. **Lớp 1 — Texture mặt đất seamless tileable (`assets/textures/ground/`, phía anh tạo):**
   - Mỗi biome cần **2 bộ texture lặp liền mạch (seamless)**: **nền chính** (cỏ rêu / bùn / tro / đá nứt / tuyết / gạch cổ) và **nền phụ** (đất mòn / sỏi / rêu đậm).
   - Mỗi bộ gồm `albedo.png` (1024×1024, không có bóng nắng nung sẵn), `normal.png` (tạo từ heightmap), `roughness.png` (hoặc grayscale).
   - Phía Godot dùng `shaders/biome_ground.gdshader` để **pha trộn 2 texture theo noise đa tầng + triplanar/UV** và làm mềm ranh giới giữa 6 biome (hết trơn lì và hết vệt lưới).
2. **Lớp 2 — Phủ nền `MultiMesh` (`assets/models/nature/decor/`, phía anh tạo):**
   - Bụi cỏ (`decor_grass_tuft` 3 mẫu), cụm sỏi (`decor_pebbles`), hoa dại, dương xỉ, nấm nhỏ, gỗ mục.
   - **BẮT BUỘC low-poly ≤ 80–150 tam giác/mẫu** (tắt `HGK_KEEP=1` khi fit nhóm này) để Godot rải hàng nghìn cụm bằng `MultiMeshInstance3D` mà vẫn mượt 60 FPS.
3. **Lớp 3 — Bóng tiếp đất & đường mòn (phía Godot tự xử lý):**
   - Bóng đổ mềm + `ContactShadow` dưới chân mọi thực thể + decal/đá lát cho `ruin_path`, `mud`, `floor_trap`.

## Lưu ý kỹ thuật rút ra từ Đợt 1 (bắt buộc sửa trước Đợt 2)

1. **Lỗi `metallicFactor` mặc định = 1.0 trong GLB:** 60/63 GLB ở Đợt 1 xuất ra bị thiếu `metallicFactor` trong JSON glTF (glTF mặc định là `1.0` nếu bỏ trống), khiến model bị đen sì trong Godot nếu không vá bằng code. Trong `hgk_fit.py`, phải gán rõ `metallic = 0.0` sao cho exporter ghi `"metallicFactor": 0.0` vào GLB, và bỏ `KHR_materials_specular = 2.0`.
2. **Độ sáng texture:** Texture Đợt 1 có độ sáng trung bình khá tối (~0.24 sRGB). Khi kéo màu về bảng màu ở `hgk_fit.py`, nâng sáng nhẹ (~15–20%) để cây/đá/nhân vật không bị bệt tối dưới ánh sáng ban ngày.
3. **Ngân sách tam giác cho đồ rải nhiều (`nature/decor/`):** Model đơn lẻ (cây, công trình, yêu thú) có thể giữ mesh Omni ~40k tam giác; riêng nhóm `decor_*` dùng cho `MultiMesh` **không được vượt quá 150 tam giác**.

## Khung kỹ thuật (bắt buộc, không tự ý đổi)

| Mục | Quy ước |
|---|---|
| Engine | Godot 4.7.2. Import GLB (glTF 2.0 nhị phân) |
| Đơn vị | 1 đơn vị = 1 mét. Nhân vật người chơi cao **1,7 m** làm thước đo chung |
| Trục | Y hướng lên. Trong Blender: mặt trước của model quay về **-Y** (nhìn thấy mặt khi bấm Front view). Khi xuất glTF, mặt trước thành +Z, khớp `MODEL_FRONT` của Godot |
| Pivot | Vật đặt trên đất (cây, đá, công trình, yêu thú, nhân vật): tâm đáy, đúng mặt đất. Công cụ và vũ khí cầm tay: điểm tay nắm (xem phase-03) |
| Transform | Apply toàn bộ location, rotation, scale trước khi xuất. Scale object = 1 |
| Camera game | Phối cảnh nghiêng khoảng 45–55 độ, nhìn từ trên xuống. Phần mặt trên và mặt trước của model là phần người chơi thấy nhiều nhất |
| Material | **Một material mỗi model** (trừ khi catalog ghi khác). Không metallic, roughness = 1, không normal map |
| Texture | Chỉ albedo (màu nền). PNG. Cỡ theo catalog: 256, 512 hoặc 1024. Không có ánh sáng, bóng đổ hay điểm sáng bóng nung vào texture |
| Số tam giác | Theo ngân sách trong catalog. Vượt quá 20% thì phải giảm (decimate) |
| Hoạt ảnh | Nằm chung trong file GLB, tên clip viết thường tiếng Anh (`idle`, `walk`...). 30 fps |

## Phong cách (tóm tắt từ GDD 1.1)

- **Hình khối:** low-poly đến mid-poly, tỉ lệ hơi cách điệu, khối lớn rõ ràng. Cây có tán tròn khối, đá góc cạnh mềm. Chi tiết nhỏ hơn 5 cm thì bỏ.
- **Không khí:** thế giới hoang dã **u ám**, đè nén, kiểu sinh tồn DST. Mọi thứ trông cũ, bạc màu, dãi dầu mưa nắng.
- **Màu (quy tắc 80/20):** 80% là màu đất trầm, độ bão hòa thấp (ô liu, nâu đất, gỉ sắt, tím tro, đá xám nâu). 20% màu rực chỉ dành cho điểm nhấn gameplay: Linh Thạch, linh khí, quả chín, lửa, mắt yêu thú. Tô kiểu tranh vẽ, chuyển sắc mềm, không chân thực.
- **Không phải tu tiên, không phải cổ phong thuần.** Người chơi lạc vào một thế giới hoang dã huyền bí, rải rác phế tích của nền văn minh đã mất (đá nguyên khối, phù văn phát sáng, mảnh đá lơ lửng). Không làm mái cong, cổng tam quan, đèn lồng kiểu tông môn.
- **Công trình người chơi:** đồ sinh tồn chắp vá từ gỗ, đá, xương, da, dây thừng. Đồ bậc cao gắn thêm mảnh phế tích (đá khắc phù văn, tinh thể Linh Thạch).
- **Không có:** viền đen nét mực, chữ, logo, chi tiết sci-fi, vật liệu kim loại bóng.
- Bảng màu chuẩn ghi ở [phase-01](phase-01-style-lock-and-setup.md). Mọi texture phải lấy màu từ bảng đó.
- Trong Godot, model được tô bằng shader toon `shaders/painted_gradient.gdshader` (ánh sáng 2 bậc mềm). Vì vậy texture chỉ cần màu phẳng và chuyển sắc nhẹ, không cần tô bóng sáng.

## Quy trình cho mỗi asset (tóm tắt)

```
Ảnh concept → Hunyuan3D-Omni (hình khối, có khống chế) → Blender: làm sạch, giảm poly, UV
→ Texture (Hunyuan3D-Paint rồi làm phẳng, hoặc tô bảng màu) → Rig + hoạt ảnh (nếu là sinh vật)
→ Xuất GLB → Kiểm tra checklist → Ghi manifest → Commit lên nhánh assets/*
```

Chi tiết từng bước nằm ở [phase-01](phase-01-style-lock-and-setup.md) mục "Quy trình chuẩn".

## Quy trình tự đánh giá & tự duyệt (dành cho Claude bên máy tạo asset)

Không dừng lại chờ chủ dự án duyệt tay. Sau khi `hgk_fit.py` và `preview.py` xuất ảnh xem trước (góc 3/4 từ trên xuống + đứng cạnh hình nhân 1,7 m), Claude tự kiểm tra từng món:
1. **Đúng hình dáng & công năng:** Không sai vật thể (vd giáo không ra rìu, giáp không ra vòng), không chẻ đôi cán công cụ, không bị dẹt/mất khối, không thừa mảnh rác lơ lửng.
2. **Đúng tỉ lệ, pivot & hướng:** Chiều cao/dài khớp catalog khi đặt cạnh hình nhân 1,7 m; đáy `y = 0`; mặt trước quay đúng hướng.
3. **Màu sắc & kỹ thuật:** Đúng bảng màu 80/20, không quá tối bệt; GLB có `"metallicFactor": 0.0` (không mặc định 1.0); nhóm `decor_*` ≤ 150 tam giác; sinh vật có đủ rig và hoạt ảnh không biến dạng lưới.
4. **Xử lý khi chưa đạt:** Tự đổi seed/prompt concept hoặc chỉnh thông số và tạo lại ngay (tối đa 3 lần; nếu vẫn không đạt mới ghi `known_issue` để báo lại).
5. **Tự duyệt & bàn giao:** Khi đạt toàn bộ mục trên, tự điền `"approved_by": "claude-auto"` và `"approved_date": "YYYY-MM-DD"` vào `assets/asset-manifest.json`, giữ `technical_checks_passed: true`, rồi commit và mở Pull Request vào `main`.

## Các giai đoạn & Đợt bàn giao

| Đợt | Nội dung chính | Trạng thái |
|---|---|---|
| **Đợt 1** | 59 món P0 / 63 GLB (thiên nhiên 9, công trình 8, yêu thú 3 có rig, nhân vật 1 tĩnh, vật phẩm 38) + pipeline + cảnh `asset_review` | ✅ Đã xong & đã gắn vào gameplay |
| **Đợt 2** | **Ưu tiên cao nhất:** (2A) Sửa 7 món lỗi Đợt 1 + rig nhân vật chính + tách socket lửa trại; (2B) **Texture nền đất seamless 6 biome + `nature/decor/` low-poly**; (2C) Hoàn thiện Rừng Linh Trúc (`bamboo_cluster`, `forest_pheasant`, `teleport_array`, `ruin_path`, `floor_trap`, `mud`, `bush_grass`, biến thể `stump`/`picked`) | ⬜ Tiếp theo |
| **Đợt 3** | 3 nhân vật còn lại + dạng Hóa Thú; 13 công trình nâng cao; 4 Khôi Lỗi; 3 NPC; 4 object Bí Cảnh | ⬜ Kế tiếp |
| **Đợt 4** | 5 Biome còn lại: 14 yêu thú thường + Tâm Ma + 6 Boss + tài nguyên & phế tích đặc trưng từng biome | ⬜ Sau Đợt 3 |

Chi tiết danh sách từng món nằm ở [asset-catalog.md](asset-catalog.md).

## Cách giao nhận qua GitHub

- Repo: `github.com/ngoctienvt/hoang-gioi-ky` (public). Clone về, làm trên nhánh `assets/<đợt>`, ví dụ `assets/nature-batch-1`, rồi mở Pull Request vào `main`.
- **Chỉ commit:** file `.glb` đã qua kiểm tra, texture PNG đi kèm (nếu không nhúng trong GLB), ảnh xem trước nhỏ, và phần cập nhật `assets/asset-manifest.json`.
- **Không commit:** ảnh concept gốc, mesh thô Omni xuất ra, file `.blend`. Các file này để trong `art-source/` (đã nằm trong `.gitignore`) và lưu trữ riêng (ổ cứng ngoài hoặc Google Drive).
- Mỗi PR một đợt, tối đa khoảng 15 asset, kèm ảnh contact sheet chụp tất cả asset đứng cạnh hình nhân 1,7 m.

## Rủi ro

- **Lệch phong cách giữa các đợt.** Luôn dùng 3 asset mẫu đã duyệt làm ảnh tham chiếu, không lấy asset vừa làm xong làm mẫu cho cái tiếp theo.
- **Mesh Omni quá dày, topology rối, không dùng được cho rig.** Luôn giảm poly và kiểm tra. Nhân vật và yêu thú có thể cần retopo (dựng lại lưới) trên mesh Omni.
- **Texture Paint ra kiểu PBR chân thực, có bóng nung sẵn.** Phải làm phẳng lại theo bảng màu (phase-01, bước 5).
- **Giấy phép Hunyuan3D.** Giấy phép cộng đồng của Tencent Hunyuan có giới hạn lãnh thổ và quy mô người dùng. Phải đọc file LICENSE trong repo Hunyuan3D-Omni và Hunyuan3D-2.1 trước khi phát hành, ghi vào manifest (xem câu hỏi chưa chốt).

## Câu hỏi chưa chốt

1. Giấy phép Hunyuan3D có cho phép bán game ở mọi thị trường dự kiến (đặc biệt EU, Anh, Hàn Quốc) không? Cần chủ dự án đọc LICENSE và quyết định trước khi lên Steam.
2. Ảnh concept tạo bằng công cụ gì trên máy anh (Flux, SDXL, hay tự vẽ)? Plan viết chung, chỉ cần ảnh đạt yêu cầu ở phase-01.
3. Nơi lưu `art-source/` lâu dài (ổ ngoài, Google Drive, hay Git LFS sau này)?
