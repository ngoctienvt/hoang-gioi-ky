## Đồng hồ thế giới: chu kỳ ngày 8 phút, tỉ lệ ngày/chạng vạng/đêm theo mùa.
## Host chạy đồng hồ và đồng bộ xuống client. Phát EventBus.day_phase_changed khi đổi pha.
## Phần cài đặt làm ở giai đoạn 06.
extends Node

const DAY_LENGTH_SECONDS: float = 480.0
