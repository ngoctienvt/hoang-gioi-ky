## Quản lý phiên mạng: một người chơi làm host (ENet), những người khác vào qua IP/LAN.
## Host có quyền quyết định trạng thái thế giới; client chỉ gửi yêu cầu request_* lên host.
## Phần cài đặt làm ở giai đoạn 02.
extends Node

const DEFAULT_PORT: int = 24565
const MAX_PLAYERS: int = 4
