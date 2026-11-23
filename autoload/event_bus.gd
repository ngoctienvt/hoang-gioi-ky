## Kênh signal toàn cục, giúp các hệ thống báo cho nhau mà không cần tham chiếu trực tiếp.
## Chỉ khai báo signal ở đây, không chứa logic. Thêm signal khi giai đoạn sau cần.
extends Node

## Một người chơi vào hoặc rời phiên (peer_id theo multiplayer).
signal player_joined(peer_id: int)
signal player_left(peer_id: int)

## Đổi pha trong ngày: "day", "dusk", "night".
signal day_phase_changed(phase: StringName)
signal day_started(day_number: int)

## Một vật phẩm được chế thành công lần đầu, Thiên Thư của cả nhóm cập nhật.
signal recipe_unlocked(recipe_id: StringName)

## Người chơi chết (thành Hồn Phách) hoặc được hồi sinh.
signal player_died(peer_id: int)
signal player_revived(peer_id: int)
