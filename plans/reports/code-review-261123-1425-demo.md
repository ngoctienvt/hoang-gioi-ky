# Demo review — 2026-11-23

Scope: accepted demo plan phases 02–10; changed autoload, components, Resource data, simulation, UI/view and ENet intent boundary. Reviewed source and ran headless GUT under Godot 4.7.2 .NET. No commit performed.

## Current actionable findings

- **P1 — exported builds can lose all dynamic item/recipe discovery.** `autoload/item_db.gd:11`, `autoload/recipe_db.gd:14`, `autoload/recipe_db.gd:20` use `DirAccess.get_files_at` and accept only `.tres`. Godot converts text resources and lists remapped filenames in exported projects. Replace these resource loops with `ResourceLoader.list_directory`; retain DirAccess for user save files. This follows official [DirAccess documentation](https://docs.godotengine.org/en/4.4/classes/class_diraccess.html). Root informed; packed build was not run by this reviewer.
- **P2 — wiki tag values remain English internal identifiers.** `ui/demo/demo_recipes.gd` prints minimum/maximum/forbidden dictionaries through `str(value)`. Vietnamese labels alone do not translate fruit/meat/herb/wood/healing. Format tag names through translation keys. UI owner informed.

## Verified fixes during review

- Food use now passes ItemDef; material use/equip rejected.
- Alchemy now uses actual numeric recipe chance and solvent bonus, rather than casting matched-success boolean to probability.
- Resource exhaustion rejects extra rock harvest; rock data now three stages of three hits, normal tree fifteen hits.
- Revival penalty records `stats.revivals`; survives following simulation tick.
- Stack merging ignores transport fields id/count/durability while preserving meaningful metadata, including separate water expiry times. Pickup and chest transfer retain metadata.
- Same-name reconnect restores parked player inventory/stats/position; loaded active player state is parked offline.
- Expired spirit water remains a valid plain_water item; bush replant items and monkey fur have Resource definitions.
- Ghost movement collision mask updated by host.
- UI owner reports and source shows workbench proximity participates in refresh, crop harvest dispatch matches server, save menu refreshes, altar accepts resource deposits and revival.

## Acceptance evidence

- **PASS:** 28/28 GUT tests, 173 assertions, exit 0. Command: Godot console `--headless --path . -s addons/gut/gut_cmdln.gd -gexit`, APPDATA/LOCALAPPDATA redirected inside `.runtime`.
- Coverage: inventory stack/split/full/rollback/durability/serialization, tag priority/forbidden/fallback/alchemy chances, clock boundaries, darkness/fire/hunger/poison, save native-type roundtrip and path rejection, content loading, invalid remote payload shapes/counts/proximity, exactly-once pickup, ghost restrictions, food, shared four-ingredient pot and single output, farm acceleration, ability cost/cooldown, restore/reconnect, altar cost/penalty, rock exhaustion, roast/eat, automatic madness friendly-fire exception, water expiry.
- Content loaded in test: 56 items, 17 crafting recipes, five named meals plus burnt fallback, four alchemy recipes, ten resource nodes, three creatures.
- RPC review: actions identify sender through `get_remote_sender_id`; host checks registered player, size/rate limits, ghost, slots/counts, tier, proximity and crafting materials. Movement clamps finite vectors and runs server-side; client cannot submit arbitrary position/world state. Save paths accept only bounded ASCII slot names, host saves, bounded JSON native envelope; no object decoding permission enabled. No credentials inspected.
- Script compile/integration smoke and real ENet process tests are root-owned; do not replace those results with this unit-test evidence.

## Mandatory completion gaps

These are verification/delivery requirements, not optional polish: packaged Windows build and export resource loading; actual 2–4-player LAN/IP session; ten Autumn days on multiple machines. This reviewer did not observe those runs. Do not mark all demo acceptance complete from headless tests or two local process logs.

Optional visual refinement includes richer art, animations and authored audio beyond current demo placeholders; it does not block the documented greybox demo.

Unresolved: export resource scanner fix and packed-build test; Vietnamese wiki tag formatting; externally observed LAN ten-day run.

## Addendum — 2026-11-23, chốt triển khai

Đã đối chiếu nguồn: ItemDB/RecipeDB chuyển sang ResourceLoader.list_directory; wiki dịch tên thẻ qua TAG_* — hai finding ở trên đã được xử lý. Root bổ sung dọn collider/visual/preview khi rời phiên, preview khớp host và lỗi tải slot không sinh thế giới mới. Không chạy lại game/test/compile/UI sau yêu cầu dừng của chủ dự án; 28/28 là kết quả lịch sử trước các thay đổi cuối, không phải xác nhận build cuối. Windows export và LAN 10 ngày vẫn chờ chủ dự án. Xem [báo cáo triển khai](implementation-261123-1425-demo.md).
