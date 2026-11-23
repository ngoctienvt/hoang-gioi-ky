# Giai đoạn 03 — Vật phẩm, kho đồ & đồ dưới đất

## Mục tiêu
Có hệ vật phẩm dữ liệu hóa, kho đồ kiểu DST, ô cầm tay, độ bền, nhặt và thả đồ đồng bộ qua mạng.

## Việc cần làm
1. **ItemDef:** id, khóa tên, icon, số lượng chồng tối đa, loại (nguyên liệu, công cụ, vũ khí, thức ăn, đan, công trình), thẻ thuộc tính kèm giá trị (dùng cho nồi và lò ở giai đoạn 07, 09), độ bền tối đa, loại công cụ (rìu, cuốc, xẻng), sát thương.
2. **Vật phẩm demo đầu tiên:** cành khô, cỏ sợi, đá lửa, gỗ, linh trúc, đá, Linh Thạch, quả linh, nấm trắng, củ hoang.
3. **InventoryComponent:** thanh hotbar 15 ô như DST, cộng ô tay, ô thân, ô đầu. Gộp chồng, tách chồng, đổi chỗ. Logic thuần, có test GUT.
4. **Độ bền:** công cụ và vũ khí giảm độ bền mỗi lần dùng, hỏng thì biến mất. Hiển thị thanh độ bền trên icon.
5. **Đồ dưới đất (GroundItem):** thả đồ ra đất, nhặt lên (bấm phím hoặc click). Host spawn và xóa, đồng bộ cho mọi người.
6. **Giao diện kho đồ:** hotbar dưới màn hình, kéo thả, chuột phải để dùng hoặc trang bị, Shift click để thả.
7. Kho đồ của mỗi người do host giữ. Client chỉ hiển thị bản sao.

## Hoàn thành khi
- Test GUT cho gộp chồng, tách chồng, đầy kho, độ bền đều qua.
- Hai người cùng thả và nhặt đồ, không có đồ bị nhân đôi hay biến mất.

## Rủi ro
- Hai người nhặt cùng một món cùng lúc: host xử lý yêu cầu đầu tiên, yêu cầu sau bị từ chối.
