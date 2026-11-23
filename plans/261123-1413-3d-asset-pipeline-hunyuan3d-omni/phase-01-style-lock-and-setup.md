# Giai đoạn 01 — Cài đặt, khóa phong cách & 3 asset mẫu

## Mục tiêu

Dựng đủ công cụ trên máy, chốt bảng màu và quy trình chuẩn, làm 3 asset mẫu để chủ dự án duyệt. Sau giai đoạn này mọi asset khác chỉ việc lặp lại quy trình.

## Công cụ cần có

| Công cụ | Dùng để | Ghi chú |
|---|---|---|
| **Hunyuan3D-Omni** (`github.com/Tencent-Hunyuan/Hunyuan3D-Omni`, trọng số `tencent/Hunyuan3D-Omni` trên Hugging Face) | Ảnh → hình khối 3D, có khống chế bằng `bbox`, `point`, `voxel`, `pose` | Chỉ ra **hình khối, không có texture**. Đọc README của repo để lấy đúng lệnh chạy và tên tham số; plan này không ghi lệnh cụ thể vì có thể đổi theo phiên bản |
| **Hunyuan3D-Paint** (trong repo `Tencent-Hunyuan/Hunyuan3D-2.1`) | Tô texture cho mesh từ ảnh concept | Tùy chọn. Ra texture kiểu PBR, phải làm phẳng lại (bước 5) |
| **Blender 4.x** | Làm sạch, giảm poly, UV, tô màu, rig, hoạt ảnh, xuất GLB | Bắt buộc |
| Công cụ tạo ảnh concept (Flux, SDXL... chạy local) hoặc vẽ tay | Tạo ảnh đầu vào cho Omni | Xem yêu cầu ảnh bên dưới |
| **Godot 4.7.2** | Mở project, xem asset trong game | Tùy chọn nhưng nên có để tự kiểm tra (phase-06) |
| Rig: Rigify (có sẵn trong Blender), AccuRig hoặc Mixamo | Rig nhân vật | Xem phase-05 |

## Việc cần làm

1. Cài Hunyuan3D-Omni theo README, chạy thử ví dụ có sẵn của repo cho chắc chạy được trên GPU của máy.
2. Clone repo game, tạo cấu trúc thư mục:
   ```
   assets/
     models/
       nature/  items/  structures/  creatures/  characters/
     asset-manifest.json
   art-source/          (không commit, đã có trong .gitignore)
     concepts/  raw-omni/  blend/  previews/
   ```
3. Tạo **hình nhân thước đo**: khối người cao 1,7 m (hộp hoặc capsule) trong file Blender mẫu `art-source/blend/_scale_reference.blend`. Mọi asset phải đặt cạnh hình nhân này khi kiểm tra.
4. Tạo **bảng màu chuẩn** `assets/palette.png` (ảnh 16×16 ô, mỗi ô 16 px, tổng 256×256) từ các màu dưới đây. Mọi texture lấy màu từ bảng này hoặc chuyển sắc giữa các màu trong bảng.
5. Làm 3 asset mẫu theo "Quy trình chuẩn" bên dưới: **cây gỗ thường (dạng đứng)**, **lửa trại**, **sói rừng (chưa cần rig)**.
6. Chụp 3 asset mẫu cạnh hình nhân, nhìn từ góc camera game (nghiêng 50 độ), gửi chủ dự án duyệt. Sửa tới khi được duyệt.
7. Ghi vào `assets/asset-manifest.json` 3 asset mẫu, đánh dấu `"style_anchor": true`.

## Bảng màu chuẩn (biome Rừng Linh Trúc, mùa Thu)

**Không khí: thế giới hoang dã u ám, kiểu sinh tồn DST.** Theo quy tắc 80/20 của GDD 1.1: màu nền trầm, bạc, ngả đất. Chỉ nhóm "Điểm nhấn" bên dưới mới được rực. Đã thử trên cảnh `world/style_test/style_test.tscn`, xem ảnh `plans/reports/style-test-261123-1429-canh-thu-u-am.png`.

**Màu nền (chiếm phần lớn mọi asset):**

| Vai trò | Hex | Dùng cho |
|---|---|---|
| Lá ô liu sáng | `#808C47` | Mặt trên tán cây, cỏ |
| Lá ô liu đậm | `#4E5B32` | Mặt dưới tán cây |
| Lá rất đậm | `#2E3624` | Bóng trong tán, bụi rậm |
| Cỏ úa | `#5F6340` | Mặt đất cỏ, búi cỏ |
| Đất | `#6B5A3E` | Đất trống, hang thỏ, luống ruộng |
| Trúc xanh xám | `#7E9C6E` | Thân linh trúc |
| Tán gỉ sắt (Thu) | `#94472E` | Cây điểm xuyết, lá đỏ |
| Tán vàng đất (Thu) | `#B37636` | Cây điểm xuyết |
| Tán tím tro | `#5C4A63` | Cây điểm xuyết, hoa |
| Gỗ sáng | `#A07A52` | Gỗ đã chặt, cán công cụ |
| Gỗ thân cây | `#5C4332` | Vỏ cây |
| Gỗ tối | `#33261E` | Khe vỏ, gốc cây |
| Đá sáng | `#8F8C80` | Mặt trên đá |
| Đá xám nâu | `#6B6A62` | Thân đá |
| Đá tối | `#3E3D3A` | Khe đá |
| Cỏ khô / rơm | `#B89E62` | Giáp cỏ, mái rơm, dây thừng |
| Da lông nâu | `#6E4E38` | Sói, da lông |
| Lông xám | `#6A6763` | Sói |
| Lông trắng ngà | `#CFC6B4` | Thỏ linh |
| Lông khỉ nâu vàng | `#9A774A` | Khỉ linh |
| Đỏ sơn mài cũ | `#852D26` | Chi tiết công trình, Hồi Hồn Đài |
| Đồng cũ | `#A88B4E` | Viền đồ quý, Lò Đan |
| Da người | `#C9A386` | Nhân vật |

**Điểm nhấn (được rực, chỉ dùng cho thứ quan trọng với gameplay, mỗi asset tối đa một vùng nhỏ):**

| Vai trò | Hex | Dùng cho |
|---|---|---|
| Linh Thạch | `#5FD3E0` | Tinh thể Linh Thạch (Godot thêm phát sáng) |
| Linh khí | `#9FE8C8` | Đan dược, Thanh Mộc Tuyền, Hồn Phách, Linh Quả biến dị |
| Quả chín | `#D9532E` | Quả linh, quả trên bụi |
| Lửa | `#F29A3A` | Than hồng, đầu đuốc |
| Mắt yêu thú | `#E8C24A` | Mắt sói, mắt khỉ |

Được thêm màu mới khi cần, nhưng phải ghi vào bảng này và báo chủ dự án. Màu nền mới phải trầm, độ bão hòa thấp như các màu trên.

## Yêu cầu ảnh concept (đầu vào cho Omni)

- **Một vật thể duy nhất**, nằm giữa ảnh, thấy trọn vẹn, không bị cắt mép.
- Nền trắng hoặc xám nhạt trơn. Không có cảnh, không có bóng đổ dưới đất.
- Góc nhìn nghiêng 3/4 từ phía trước, hơi từ trên xuống. Với nhân vật và yêu thú: nhìn thẳng phía trước, tư thế A-pose (nhân vật) hoặc đứng thẳng 4 chân (thú).
- Ánh sáng phẳng, đều. Không có ánh đèn mạnh, không có điểm sáng bóng.
- Ảnh vuông, từ 1024×1024 trở lên.
- Không chữ, không logo, không chữ ký.

**Mẫu prompt tạo ảnh concept** (thay phần trong ngoặc vuông):

```
stylized low-poly 3D game asset, [MÔ TẢ VẬT THỂ], gloomy mysterious fantasy wilderness with ruins of a lost ancient civilization,
survival game mood, hand-painted flat colors with soft gradients,
muted earthy desaturated palette, olive green, umber brown, rust, ash grey,
weathered and worn, chunky simple shapes, soft rounded forms,
single object centered, full object visible, three-quarter front view from slightly above,
plain light grey background, flat even lighting, no shadow, no text, no outline
```

Prompt phủ định (negative): `bright saturated colors, cheerful, cute pastel, neon, photorealistic, PBR, shiny metal, high detail noise, text, logo, watermark, multiple objects, ground, scene, harsh shadow, black outline, cropped`.

Ảnh concept ra vẫn tươi quá thì không sao: khi tô texture (bước 5) màu luôn kéo về bảng màu chuẩn ở trên.

## Quy trình chuẩn (áp dụng cho mọi asset)

1. **Concept.** Tạo hoặc vẽ ảnh theo yêu cầu trên. Đưa thêm ảnh của 3 asset mẫu đã duyệt làm ảnh tham chiếu phong cách nếu công cụ ảnh hỗ trợ. Lưu vào `art-source/concepts/<id>.png`.
2. **Hình khối bằng Omni.** Chạy Omni với ảnh concept, cộng thêm khống chế phù hợp:
   - `bbox`: luôn dùng, đặt theo kích thước trong `asset-catalog.md` để giữ đúng tỉ lệ dài, rộng, cao.
   - `point` hoặc `voxel`: dùng khi đã có khối greybox trong Blender (ví dụ công trình, các giai đoạn đá vỡ). Xuất point cloud từ greybox (khoảng 2048 điểm) để Omni bám theo hình đó. Rất hữu ích để nhiều biến thể hoặc nhiều giai đoạn giữ cùng khung.
   - `pose`: dùng cho nhân vật, để ra đúng tư thế A-pose dễ rig.
   - Tạo 2–4 kết quả, chọn cái có hình bóng (silhouette) rõ nhất khi nhìn từ trên xuống. Lưu vào `art-source/raw-omni/`.
3. **Làm sạch trong Blender.**
   - Scale đúng kích thước mét theo catalog, đặt pivot, quay mặt trước về -Y, apply transform.
   - Xóa mảnh rời, mặt bên trong, lỗ thủng nhỏ. Merge by distance. Recalculate normals ra ngoài.
   - Giảm poly (Decimate hoặc retopo) về ngân sách tam giác. Ưu tiên giữ hình bóng, bỏ chi tiết nhỏ.
   - Shade flat hoặc auto smooth khoảng 30–40 độ để ra cảm giác low-poly mềm.
4. **UV.** Smart UV Project là đủ cho vật tĩnh. Nhân vật và yêu thú cần UV gọn hơn để tô.
5. **Texture**, chọn một trong hai cách:
   - **Cách A, bảng màu (khuyên dùng cho cây, đá, bụi, công cụ, công trình):** gán UV từng vùng vào ô màu tương ứng trên `assets/palette.png`. Nhanh, đồng bộ tuyệt đối, texture dùng chung cho cả họ asset.
   - **Cách B, Hunyuan3D-Paint (cho nhân vật, yêu thú, đồ có hoa văn):** tô bằng Paint từ ảnh concept, rồi trong Blender hoặc phần mềm ảnh: bỏ map metallic, roughness và normal; giảm nhiễu chi tiết nhỏ; xóa vùng sáng bóng và bóng tối nung sẵn; kéo màu về gần bảng màu chuẩn; bake ra một ảnh albedo đúng cỡ trong catalog.
6. **Rig và hoạt ảnh** (chỉ nhân vật, yêu thú): xem phase-05.
7. **Xuất GLB.** File → Export → glTF 2.0, định dạng `.glb`, bật "+Y Up", "Apply Modifiers", chỉ xuất object đã chọn. Texture palette dùng chung thì **không nhúng** (để Godot dùng chung một file); texture riêng thì nhúng vào GLB.
8. **Kiểm tra** theo checklist ở phase-06.
9. **Ghi manifest** (mẫu bên dưới), chụp ảnh xem trước, commit.

## Mẫu một mục trong `assets/asset-manifest.json`

```json
{
  "id": "tree_common_a",
  "file": "assets/models/nature/tree_common_a/tree_common_a_standing.glb",
  "category": "nature",
  "priority": "P0",
  "style_anchor": true,
  "dimensions_m": [3.2, 3.0, 6.0],
  "triangles": 3400,
  "texture": "assets/palette.png",
  "animations": [],
  "source": {
    "kind": "ai_generated_then_edited",
    "concept_tool": "Flux.1-dev (local)",
    "mesh_tool": "Hunyuan3D-Omni <phiên bản hoặc commit>",
    "texture_tool": "palette (tô tay trong Blender)",
    "controls": ["bbox"],
    "human_edits": "decimate, UV palette, chỉnh tán lá"
  },
  "license": "xem LICENSE của Hunyuan3D-Omni",
  "technical_checks_passed": true,
  "approved_by": "chủ dự án",
  "approved_date": "2026-11-30"
}
```

## Hoàn thành khi

- Omni chạy được trên máy, có quy trình lặp lại được.
- Có `assets/palette.png` và `_scale_reference.blend`.
- Chủ dự án duyệt 3 asset mẫu. Từ đây 3 asset này là chuẩn phong cách.

## Rủi ro

- GPU không đủ VRAM cho Omni: giảm độ phân giải đầu ra hoặc chạy chế độ tiết kiệm bộ nhớ theo README, chấp nhận mesh thô hơn vì đằng nào cũng giảm poly.
- Chọn sai phong cách ngay từ mẫu thì cả bộ hỏng theo. Không làm hàng loạt trước khi 3 mẫu được duyệt.
