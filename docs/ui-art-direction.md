# Giao diện Hoang Giới Ký

## Hướng hình ảnh

Tham khảo cách phân vùng của ảnh DST do chủ dự án cung cấp ngày 2026-11-23. Asset được vẽ mới: nền than tối, đồng cũ, chữ ngà; ngọc xanh cho trạng thái chọn và linh khí. Giữ không khí phế tích hoang dã trong [GDD](game-design-document.md), tránh hoa văn tông môn cầu kỳ.

## Bố cục đang tích hợp

- Trái: thanh danh mục bằng icon 44px, tên hiện khi rê chuột; bảng công thức mở kế bên. Công thức hiện vẫn là danh sách có icon và nguyên liệu, chưa đổi sang grid như concept.
- Dưới: 15 ô vật phẩm 60×64px, icon 44px, số thứ tự góc trái, số lượng góc phải. Tên đầy đủ và hướng dẫn trong tooltip. Viền xanh đánh dấu ô chọn; thanh dưới hiển thị độ bền hoặc độ tươi; đồ gần hỏng chuyển đỏ.
- Trên phải: đồng hồ ngày/đêm, ba vòng Khí Huyết/Thể Lực/Đạo Tâm có biểu tượng, nhãn và giá trị.
- Phải: bảng mục tiêu dưới cụm chỉ số; minimap trên thanh vật phẩm.
- Trên giữa: mùa, thời tiết, nhiệt độ, biome và thao tác nhanh. Trung tâm ưu tiên cảnh chơi.

Nền tham chiếu UI là 1280×800 theo project hiện tại. Dùng anchors cho mép trên/phải/dưới, containers cho hàng/cột và scroll cho nội dung dài. Chưa xác nhận runtime ở độ phân giải khác hoặc điều khiển gamepad.

## Asset và tái tạo

- [Bảng xem 180 icon](../plans/reports/ui-icons-261123-1548.html): 164 vật phẩm, 16 HUD/danh mục. SVG trong suốt, canvas 96×96; không cần font hoặc ảnh ngoài.
- [Manifest](../assets/ui/asset-manifest.json): ID, họ hình, đường dẫn, nguồn và kiểm tra kỹ thuật. Biến thể cùng họ dùng chung hình khối; màu thể hiện chất liệu/biome, dấu thoi thể hiện bậc đan/lõi. Tooltip vẫn là tên nhận diện chính.
- Tái tạo vector: `node tools/generate-ui-icons.cjs`. Thêm `--assign` khi thêm icon vào ItemDef chưa có liên kết; không ghi đè liên kết icon đã có.
- Kiểm tra tĩnh: `powershell -File tools/validate-ui-assets.ps1`. Không gọi Godot. Manifest chỉ đánh dấu kiểm tra XML/kích thước/đường dẫn; kiểm tra alpha raster và đọc ở kích thước thật trong game còn chờ.
- Dữ liệu `ItemDef.icon` trỏ trực tiếp vào SVG, dùng được qua ResourceLoader và đồ thị tài nguyên của Godot.
- Log tái tạo: `[UIAssets]`; thao tác game giữ log `[GameUI]` hiện có.

## Concept và giới hạn kiểm chứng

### Ảnh raster dùng thật (2026-11-23)

- `assets/ui/illustrations/menu-forest.png`: nền menu 1586×992, giữ tỉ lệ và crop phủ màn hình. Vùng giữa ít chi tiết để đặt form. Hiện khi mở menu, ẩn khi vào game; không nhận input. Module `ui/menu/menu_backdrop.gd`, log `[MenuArt]`.
- `assets/ui/illustrations/ability-beast.png` và `ability-sense.png`: ảnh Hóa Thú/Thú Giác, 192×192 RGBA trong suốt thật; gắn vào hai nút kỹ năng hiện có. SVG cũ vẫn giữ để dùng khi cần bản hình học giản lược.
- [Bảng xem 192/48/32px](../plans/reports/ui-art-preview-261123-1601.png), [manifest raster](../assets/ui/illustrations/art-manifest.json), [prompt nguyên bản](../plans/reports/ui-art-prompts-261123-1601.txt).
- Nguồn image_gen giữ trong `assets/ui/art-source/`; `.gdignore` ngăn Godot import các bản nguồn dung lượng lớn. Chuẩn hóa bằng `tools/prepare-ui-illustrations.ps1 -SourceDirectory <thư-mục-ảnh-đã-tạo>`. Script không gọi API và không tạo ảnh mới; chỉ sao chép, resize giữ alpha, kiểm tra và làm contact sheet.
- Đã xem ảnh nguồn và contact sheet, kiểm tra PNG/kích thước/alpha. Chưa chạy Godot để xác nhận runtime theo giới hạn README. Ảnh raster này là nội dung AI được đưa vào game, cần giữ thông tin nguồn khi khai báo phát hành.

Với game 3D, các ảnh bổ trợ khác có thể cần sau: portrait/ảnh hội thoại sau khi chốt model; tranh Thiên Thư/bestiary khi có nội dung; texture VFX và decal theo hiệu ứng thực tế. Chưa tạo các phần đó để tránh lệch ngoại hình hoặc sản xuất asset chưa có nơi dùng. Hiệu ứng động ưu tiên shader/particle; minimap vẫn lấy dữ liệu thế giới, không dùng ảnh bản đồ tĩnh.

[Ảnh phối cảnh UI](../plans/reports/ui-concept-261123-1548.png) được tạo bằng công cụ image_gen tích hợp. Đây là định hướng mỹ thuật, không phải screenshot game và không phải texture đưa vào HUD. Icon chạy trong game là vector vẽ bằng mã, giản lược hơn phần minh họa trong concept. Không dùng chữ hay icon raster từ concept để giả UI hoạt động.

Không chạy game/test/compile theo giới hạn đang ghi trong README. Trình duyệt tích hợp chặn giao thức file local nên bảng HTML chưa được xem qua công cụ đó; có thể mở trực tiếp bằng trình duyệt của máy. Cần chủ dự án kiểm tra trong game: nhìn rõ icon, tooltip, chọn ô, kéo/tách đồ, chế tác và khoảng cách các panel ở màn hình thực tế.
