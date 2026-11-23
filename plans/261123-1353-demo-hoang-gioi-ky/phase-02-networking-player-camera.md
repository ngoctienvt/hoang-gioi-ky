# Giai đoạn 02 — Mạng, nhân vật điều khiển & camera

## Mục tiêu
Host tạo phòng, người khác vào qua IP. Mỗi người có nhân vật, di chuyển và nhìn thấy nhau. Camera nghiêng cố định.

## Việc cần làm
1. **Màn hình chính:** Tạo thế giới (Host), Vào thế giới (nhập IP), Thoát. Nhập tên người chơi.
2. **NetworkManager:** `ENetMultiplayerPeer`, cổng mặc định cố định (ví dụ 24680), tối đa 4 người. Xử lý người vào, người rời, mất kết nối với host.
3. **Spawn người chơi:** `MultiplayerSpawner` cho nhân vật. Host spawn khi có người vào, xóa khi người rời.
4. **Điều khiển:** WASD di chuyển trên mặt phẳng, chuột trái để thao tác/đánh, chuột phải để dùng hoặc thả. Hỗ trợ cả click-to-move kiểu DST nếu đơn giản (tùy chọn).
5. **Quyền điều khiển:** mỗi client điều khiển nhân vật của mình (client-side prediction cho di chuyển). Vị trí đồng bộ qua `MultiplayerSynchronizer`. Mọi thao tác thay đổi thế giới (nhặt, chặt, chế) gửi lên host bằng RPC `request_*`.
6. **Camera:** góc nghiêng cố định (khoảng 45–55 độ), bám theo nhân vật, có zoom gần/xa bằng con lăn trong giới hạn.
7. **Mặt đất thử:** mặt phẳng greybox, vài khối chắn để thử va chạm.
8. **Mẫu thao tác chuẩn:** viết sẵn mẫu "client gửi yêu cầu, host kiểm tra, host đồng bộ" để mọi giai đoạn sau dùng lại.

## Hoàn thành khi
- Chạy 2 cửa sổ trên cùng máy (một host, một client qua `127.0.0.1`): cả hai thấy nhau di chuyển mượt.
- Client rời thì nhân vật biến mất ở host. Host tắt thì client về màn hình chính với thông báo.

## Rủi ro
- Lỗi đồng bộ để lâu sẽ lan ra mọi tính năng. Phải chốt mẫu thao tác ở bước 8 trước khi qua giai đoạn 03.

## Tiến độ triển khai — 2026-11-23

**Trạng thái:** Đã triển khai, chờ chủ dự án kiểm tra gameplay.

**Mã nguồn:** autoload/network_manager.gd; world/demo_session.gd; entities/demo/network_avatar.gd; world/demo_main.gd; world/demo_controls.gd. ENet host quyết định; tối đa 4 người, UDP 24565.

**Chủ dự án kiểm tra:** Hai người vào/rời qua IP, di chuyển, va chạm, camera/zoom, mất host và vào lại cùng tên.


- [x] Đã triển khai phần mã nêu trong mục tiến độ.
- [ ] Chủ dự án xác nhận gameplay và tiêu chí hoàn thành.
