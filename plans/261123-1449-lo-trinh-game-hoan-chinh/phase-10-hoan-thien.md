# Giai đoạn 10: Hoàn thiện (Menu, Cài đặt, Hướng dẫn, Rà dịch, Xuất bản Windows)

- **Trạng thái:** Hoàn thành
- **Phụ thuộc:** 01–09 (toàn bộ hệ thống gameplay đã chạy)
- **Tiêu chí liên quan:** 11, 12 (GDD mục 14, 15)

## Bối cảnh

Sau khi hoàn thành đủ vòng lặp gameplay từ 01 đến 09, giai đoạn 10 hoàn thiện trải nghiệm người dùng tối thiểu: menu cài đặt (âm lượng, đồ họa cơ bản, đổi phím), hướng dẫn chơi lần đầu ngắn gọn, rà soát toàn bộ khóa dịch `strings.csv`, cấu hình xuất bản Windows và kiểm thử toàn diện cả đơn máy lẫn mạng LAN 2 tiến trình.

## Yêu cầu

1. **Quản lý cài đặt (`autoload/settings_manager.gd`):**
   - Lưu/đọc tại `user://settings.cfg` (`ConfigFile`).
   - **Âm lượng:** `master_volume`, `sfx_volume`, `muted` (cập nhật `AudioServer` và `world_audio.gd`).
   - **Đồ họa cơ bản:** `window_mode` (`windowed`, `borderless`, `fullscreen`), `shadows` (bật/tắt bóng `DirectionalLight3D`), `fog` (bật/tắt sương `Environment`), `vsync` (an toàn khi chạy `--headless`).
   - **Đổi phím:** `rebind(action, keycode)` hỗ trợ 12 hành động (`move_up/down/left/right`, `ability_1/2/3`, `quick_work`, `interact`, `craft_menu`, `codex`, `awakening`) kèm kiểm tra trùng phím và `reset_bindings()`.
   - **Trạng thái hướng dẫn:** `tutorial_completed`.
2. **Giao diện cài đặt & Hướng dẫn:**
   - `ui/menu/settings_panel.gd`: mở được từ cả Menu chính (`main_menu.gd`) và trong game (`game_ui.gd`).
   - `ui/hud/tutorial_overlay.gd`: hướng dẫn 5 bước ngắn gọn cho người chơi lần đầu (tự ẩn nếu đã hoàn thành hoặc chạy `--probe`), có nút Sau / Trước / Bỏ qua.
3. **Rà soát khóa dịch & Kiểm thử tự động:**
   - Toàn bộ khóa mới của giai đoạn 08–10 có mặt trong `localization/strings.csv` và biên dịch lại `.translation` qua Godot `--headless --import --quit`.
   - `tests/test_settings_and_localization.gd`: kiểm tra `SettingsManager` và quét toàn bộ `.tres` trong `data/` bảo đảm không có `name_key` nào bị thiếu bản dịch tiếng Việt.
4. **Xuất bản Windows & Nghiệm thu:**
   - Tạo `export_presets.cfg` cho `Windows Desktop` (`builds/windows/HoangGioiKy.exe`). Nếu có export template 4.7.2 thì chạy xuất bản và thử khởi động; nếu chưa cài template cục bộ thì ghi nhận rõ trong báo cáo.
   - Toàn bộ GUT test qua 100%, main scene `world/game.tscn` chạy headless không lỗi, `tools/test-network.ps1 -Clients 1` (host + client LAN) qua 0 lỗi.

## Các bước

1. Tạo `autoload/settings_manager.gd` và đăng ký autoload trong `project.godot`.
2. Nối phím bấm, âm lượng, đồ họa vào `game_main.gd`, `player_controls.gd`, `game_ui.gd`, `world_view.gd`, `world_audio.gd`.
3. Tạo `ui/menu/settings_panel.gd` và `ui/hud/tutorial_overlay.gd`, gắn nút mở từ `main_menu.gd` và `game_ui.gd`.
4. Rà soát `localization/strings.csv`, chạy `--import`, viết `tests/test_settings_and_localization.gd`.
5. Tạo `export_presets.cfg`, chạy toàn bộ GUT, headless smoke và LAN probe.

## Kiểm chứng

- `tests/test_settings_and_localization.gd`: đổi phím phát hiện/xử lý trùng, lưu/tải `settings.cfg` khớp, 100% `.tres` có khóa dịch hợp lệ.
- Chạy full GUT suite, main scene headless và `tools/test-network.ps1 -Clients 1`.

## Rủi ro

- Headless mode không có cửa sổ thực: mọi lệnh `DisplayServer.window_set_mode` phải kiểm tra `DisplayServer.get_name() != "headless"`.

## Hoàn tác

- Xóa `user://settings.cfg` để về mặc định; autoload `SettingsManager` độc lập với logic mô phỏng host.
