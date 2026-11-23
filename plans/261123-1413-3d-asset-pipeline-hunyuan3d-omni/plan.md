# Kế hoạch tạo asset 3D — Hoang Giới Ký (Hunyuan3D-Omni chạy local)

- **Trạng thái:** Chưa bắt đầu
- **Ngày lập:** 2026-11-23
- **Người thực hiện:** máy của anh chủ dự án, chạy Hunyuan3D-Omni local, có AI hỗ trợ
- **Người duyệt:** chủ dự án (duyệt asset mẫu và từng đợt)
- **Nguồn thiết kế:** [GDD mục 1.1 Art direction](../../docs/game-design-document.md), [Kế hoạch demo](../261123-1353-demo-hoang-gioi-ky/plan.md)
- **Danh sách asset đầy đủ:** [asset-catalog.md](asset-catalog.md)

> File này viết cho AI bên máy tạo asset đọc. Đọc hết file này và `asset-catalog.md` trước khi tạo asset đầu tiên.

## Mục tiêu

Tạo đủ model 3D cho bản demo (biome Rừng Linh Trúc & Đồng Cỏ, mùa Thu, 1 nhân vật, 3 loài yêu thú), cùng một phong cách, đúng tỉ lệ, đúng quy ước để thả thẳng vào Godot mà không phải sửa tay. Sau demo, dùng lại đúng quy trình này cho vertical slice.

## Tiêu chí hoàn thành

1. Mọi asset có mức ưu tiên **P0** trong `asset-catalog.md` đã có file `.glb` trong `assets/models/`, đúng tên, đúng thư mục.
2. Mỗi asset qua toàn bộ checklist kỹ thuật ở [phase-06](phase-06-godot-import-and-qa.md): tỉ lệ mét, pivot, hướng mặt, số tam giác, một material, texture đúng cỡ.
3. Ba asset mẫu (cây gỗ thường, lửa trại, sói rừng) đã được chủ dự án duyệt trước khi làm hàng loạt.
4. Nhân vật và 3 loài yêu thú có rig và đủ hoạt ảnh bắt buộc.
5. `assets/asset-manifest.json` ghi đủ nguồn gốc từng asset (công cụ, phiên bản, ảnh đầu vào, ai duyệt), dùng để khai báo nội dung AI khi lên Steam.
6. Mở project trong Godot, toàn bộ GLB import không lỗi, đặt cạnh nhân vật cao 1,7 m trông đúng tỉ lệ dưới góc camera game.

## Không làm (Non-goals)

- Icon 2D của vật phẩm: phía Godot sẽ render icon từ chính file GLB. Vì vậy model cần đẹp khi nhìn nghiêng 3/4 từ trên xuống.
- Mặt đất, địa hình, cỏ phủ nền, nước: làm bằng shader và mesh trong Godot, không tạo bằng Omni.
- Hiệu ứng (lửa, khói, đom đóm, linh khí, Hắc Ám, sét): làm bằng particle trong Godot.
- Hình va chạm (collision): phía Godot tự dựng khối đơn giản.
- Asset của biome khác, Boss, nhân vật thứ 2: nằm ở mục Backlog trong `asset-catalog.md`, chỉ làm khi đã xong P0 và P1.

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

## Các giai đoạn

| # | Giai đoạn | Phụ thuộc | Trạng thái |
|---|---|---|---|
| 01 | [Cài đặt, khóa phong cách & 3 asset mẫu](phase-01-style-lock-and-setup.md) | — | Chưa làm |
| 02 | [Cây, đá, bụi: điểm tài nguyên & trang trí](phase-02-nature-resource-nodes.md) | 01 | Chưa làm |
| 03 | [Vật phẩm, công cụ, thức ăn, đan](phase-03-items-tools-food.md) | 01 | Chưa làm |
| 04 | [Công trình Sơn Môn](phase-04-structures.md) | 01 | Chưa làm |
| 05 | [Nhân vật & yêu thú (rig, hoạt ảnh)](phase-05-characters-creatures.md) | 01 | Chưa làm |
| 06 | [Import Godot, kiểm tra & bàn giao](phase-06-godot-import-and-qa.md) | 02–05 (chạy song song theo từng đợt) | Chưa làm |

Giai đoạn 02–05 làm song song được sau khi xong 01. Thứ tự khuyên dùng theo nhu cầu của kế hoạch demo: 02 → 03 → 04 → 05 (nhân vật có thể bắt đầu sớm vì rig tốn thời gian nhất).

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
