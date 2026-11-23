# Giai đoạn 04 — Thế giới & điểm tài nguyên

## Mục tiêu
Sinh một bản đồ Rừng Linh Trúc & Đồng Cỏ với đủ lớp tài nguyên. Chặt cây, đào đá, lượm đồ hoạt động như DST.

## Việc cần làm
1. **Sinh bản đồ bằng seed:** ghép các mảnh đặt sẵn (set piece) trên lưới: rừng linh trúc, rừng gỗ thường, đồng cỏ, bãi đá, khoảnh suối (chỗ cho Thanh Mộc Tuyền ở giai đoạn 09). Cùng seed thì ra cùng bản đồ. Có ranh giới bản đồ.
2. **ResourceNodeDef:** loại công cụ cần, số nhát, các giai đoạn (ví dụ cây: đứng, đổ, gốc), đồ rơi mỗi giai đoạn kèm tỉ lệ, thời gian mọc lại.
3. **Các điểm tài nguyên demo:**
   - **Cây gỗ thường:** rìu, khoảng 15 nhát, đổ ra gỗ và quả thông, để lại gốc. Xẻng đào gốc ra thêm gỗ.
   - **Linh trúc:** rìu, ít nhát, ra linh trúc, mọc lại nhanh.
   - **Tảng đá:** cuốc, vỡ 3 giai đoạn, ra đá và đá lửa.
   - **Tảng Linh Thạch:** cuốc, ra đá và Linh Thạch (hiếm hơn).
   - **Bụi linh quả:** lượm tay ra quả, mọc lại sau vài ngày.
   - **Bụi cỏ, bụi cành:** lượm tay ra cỏ sợi, cành khô, mọc lại.
   - **Đồ nằm đất:** đá lửa, nấm trắng, củ hoang rải sẵn.
4. **WorkableComponent:** nhận nhát từ công cụ đúng loại, giảm độ bền công cụ, có hiệu ứng rung và mảnh vụn khi trúng.
5. **Trồng lại:** quả thông trồng xuống đất thành cây non, lớn dần. Xẻng bứng bụi cây về trồng gần nhà.
6. **Mọc lại:** dùng `GameClock` (ngày trong game). Tạm dùng bộ đếm giây ở giai đoạn này, nối vào đồng hồ thật ở giai đoạn 06.
7. **Hiệu năng:** dùng `MultiMeshInstance3D` hoặc gom nhóm cho cỏ và vật trang trí. Chỉ đồng bộ trạng thái điểm tài nguyên khi thay đổi, không đồng bộ liên tục.

## Hoàn thành khi
- Tạo thế giới với seed bất kỳ, đi khắp bản đồ thấy đủ các loại điểm tài nguyên.
- Hai người cùng chặt một cây: số nhát cộng dồn đúng, cây đổ một lần, đồ rơi một lần.
- Người vào sau thấy đúng trạng thái cây đã chặt và đá đã đào.

## Rủi ro
- Đồng bộ trạng thái cho người vào sau: host gửi ảnh chụp trạng thái thế giới khi có người kết nối.

## Tiến độ triển khai — 2026-11-23

**Trạng thái:** Đã triển khai vòng khai thác, chờ chủ dự án kiểm tra gameplay.

**Mã nguồn:** world/simulation/world_seed.gd; world_resources.gd; world_rules.gd; data/nodes/. Cây 15 nhát; đá 3 giai đoạn × 3 nhát; gieo lại, bứng bụi, mọc lại.

**Chủ dự án kiểm tra:** Hai người cùng chặt/đào; tài nguyên chỉ rơi một lần; người vào sau thấy đúng trạng thái; đào gốc không còn vật cản.


- [x] Đã triển khai phần mã nêu trong mục tiến độ.
- [ ] Chủ dự án xác nhận gameplay và tiêu chí hoàn thành.
