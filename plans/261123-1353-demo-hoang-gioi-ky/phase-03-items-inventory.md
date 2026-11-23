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

## Tiến độ triển khai — 2026-11-23

**Trạng thái:** Đã triển khai, chờ chủ dự án kiểm tra gameplay.

**Mã nguồn:** components/inventory_component.gd; autoload/item_db.gd; data/items/; world/simulation/world_inventory.gd; ui/demo/demo_slot.gd. Kho 15 ô và tay/thân/đầu, gộp/tách/chuyển/thả, độ bền.

**Chủ dự án kiểm tra:** Hai người tranh nhặt cùng món; kho đầy; kéo thả/CTRL tách; trang bị/tháo và công cụ hỏng.


- [x] Đã triển khai phần mã nêu trong mục tiến độ.
- [ ] Chủ dự án xác nhận gameplay và tiêu chí hoàn thành.
