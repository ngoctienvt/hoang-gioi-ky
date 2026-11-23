# Giai đoạn 06 — Import Godot, kiểm tra & bàn giao

## Mục tiêu

Mọi asset trước khi commit đều qua cùng một checklist, để phía game thả vào dùng ngay. Giai đoạn này chạy song song với 02–05: mỗi đợt asset xong là kiểm tra đợt đó.

## Checklist kỹ thuật (từng asset, trong Blender trước khi xuất)

- [ ] Tên file và thư mục đúng quy ước trong `asset-catalog.md`.
- [ ] Kích thước đúng catalog (sai lệch tối đa 15%), đặt cạnh hình nhân 1,7 m trông hợp lý.
- [ ] Pivot đúng: tâm đáy chạm mặt đất (Z = 0 trong Blender), hoặc điểm tay nắm với công cụ.
- [ ] Mặt trước quay về -Y trong Blender.
- [ ] Đã apply location, rotation, scale. Scale object = (1, 1, 1).
- [ ] Số tam giác không vượt ngân sách quá 20% (xem bằng Statistics overlay của Blender).
- [ ] Không có mảnh rời thừa, mặt bên trong, mặt trùng, normal lộn ngược (bật Face Orientation: toàn màu xanh).
- [ ] Một material. Metallic = 0, Roughness = 1, không có normal map, không có emission (Godot tự thêm phát sáng).
- [ ] Texture chỉ albedo, đúng cỡ (256, 512, 1024, hoặc dùng `palette.png`), là lũy thừa của 2. Không có bóng hay điểm sáng nung sẵn.
- [ ] Màu nằm trong bảng màu chuẩn ở phase-01.
- [ ] Object con và empty socket đúng tên như catalog.
- [ ] Có rig thì: số xương trong giới hạn, chỉ xuất deform bones, mọi clip đúng tên, clip lặp khớp đầu cuối, hoạt ảnh tại chỗ.

## Kiểm tra trong Godot (nếu máy có Godot)

1. Copy GLB vào đúng thư mục `assets/models/...` trong project, mở Godot cho nó tự import. Không có lỗi hoặc cảnh báo trong bảng Output.
2. Kéo GLB vào một scene thử cạnh một `CapsuleMesh` cao 1,7 m, thêm `Camera3D` nghiêng khoảng 50 độ nhìn xuống, cách khoảng 12 m.
3. Gán thử material `ShaderMaterial` dùng `res://shaders/painted_gradient.gdshader` để xem asset dưới ánh sáng toon của game.
4. Với model có rig: mở `AnimationPlayer`, phát từng clip.
5. Chụp ảnh màn hình đặt vào `art-source/previews/` (để đính vào PR).
6. **Không commit** scene thử, không sửa file `.import` bằng tay. Phía game sẽ tự chỉnh thiết lập import (collision, LOD, material) khi đưa asset vào scene thật.

## Bàn giao (mỗi đợt một Pull Request)

1. Nhánh `assets/<tên-đợt>` tạo từ `main` mới nhất.
2. Commit gồm: các file `.glb`, texture PNG đi kèm, cập nhật `assets/asset-manifest.json`. Không commit `art-source/`.
3. Commit message dạng: `feat: add nature batch 1 models (trees, rocks, bushes)`.
4. Mô tả PR gồm:
   - Danh sách id đã làm, số tam giác, cỡ texture.
   - Ảnh contact sheet: tất cả asset trong đợt đứng cạnh hình nhân 1,7 m, nhìn từ góc camera game.
   - Ghi chú những chỗ chưa đạt hoặc cần phía game xử lý.
5. Chủ dự án duyệt PR. Asset bị từ chối thì sửa trên cùng nhánh.

## Hoàn thành khi

- Mọi asset P0 đã vào `main`, `assets/asset-manifest.json` đủ mục, mọi mục có `"technical_checks_passed": true` và `approved_by`.
- Phía game mở project, mọi GLB import không lỗi.

## Rủi ro

- File GLB lớn làm repo nặng dần. Mỗi GLB nên dưới 5 MB (nhân vật có hoạt ảnh dưới 15 MB). Nếu tổng asset vượt khoảng 500 MB thì bàn chuyển sang Git LFS.
- Hai người cùng sửa `asset-manifest.json` gây xung đột khi gộp PR: mỗi PR chỉ thêm mục mới, không sắp xếp lại các mục cũ.
