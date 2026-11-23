# Game Design Document — Hoang Giới Ký (v2)

> Cập nhật: 2026-11-23. Bản này gộp GDD gốc và mọi quyết định đã chốt qua các vòng thảo luận.
> Tên game: **Hoang Giới Ký**. Tên tiếng Anh dự kiến: *Inkwild Chronicles* (chưa chốt).

---

## 0. Các quyết định đã chốt (tóm tắt)

| Chủ đề | Quyết định |
|---|---|
| Thể loại | Sinh tồn co-op 1–4 người, 3D stylized, camera nghiêng cố định (chưa xoay) |
| Art direction | Xem mục 1.1: 3D low-poly tô màu kiểu tranh vẽ, **tông màu đất trầm, u ám kiểu sinh tồn DST** (đổi ngày 2026-11-23, trước đây là màu bão hòa ấm), **phế tích huyền huyễn của một nền văn minh đã mất** thay cho kiến trúc cổ phong thuần, sương dày. Không dùng outline nét mực cho thế giới |
| Chủ đề | **Huyền huyễn**, không phải tu tiên cảnh giới. Nhân vật là người **xuyên không** |
| Dựng Sơn Môn | Tự do chọn chỗ, không có vùng tân thủ cố định |
| Linh Mạch | Đổi thành **Linh Tuyền**: chỉ mang lợi ích (tưới cây, tôi vũ khí, ngâm/uống, dung môi lò đan). **Không** ảnh hưởng cách đặt công trình, yêu thú hay người chơi khác |
| Chế tác | Không rớt đồ sẵn. Nồi nấu và Lò Đan vận hành kiểu **crockpot** (đủ nguyên liệu là ra), có tỉ lệ thành công/thất bại. **Không mini-game** |
| Công thức | Có **wiki sẵn** (in-world là "Thiên Thư" của người xuyên không). Chế thành công lần đầu thì wiki đánh dấu đã chế |
| Boss | Rơi nguyên liệu đặc trưng, mỗi loại chỉ làm được một số ít món nhất định |
| Tiến trình | **Thức Tỉnh Bản Nguyên** 3 tầng + cây kỹ năng nhánh loại trừ + ô Ấn Ký. Không có cảnh giới |
| Đột phá | **Kiếp Nạn Thức Tỉnh và Thiên Kiếp diễn ra cùng lúc** |
| Nhân Quả | Hai thanh độc lập **Nghiệp** và **Duyên**, mỗi ngưỡng rút sự kiện có cả cơ hội lẫn hiểm họa |
| Chết | Rơi đồ, thành Hồn Phách, hồi sinh bằng Hoàn Hồn Đan hoặc Hồi Hồn Đài |
| Cả nhóm chết | Tùy chọn khi tạo thế giới: **Reset** hoặc **Chơi tiếp** |
| Kết thúc | **Thế giới mở vô tận** (tạm thời chưa có cái kết) |
| Cân bằng | Thiết kế cho 4 người, cân bằng theo kiểu DST |
| Mùa đầu | Mùa Thu |
| Tâm Ma | Có dấu hiệu nhận biết rõ ràng |
| Áo giáp | **Chưa** tôi luyện bằng Linh Thủy (chỉ vũ khí) |
| Engine | **Godot 4.7.2 bản .NET**, code game bằng GDScript. Mạng: **một người chơi làm host** |
| Đội làm | Chủ dự án + AI. Mục tiêu trước mắt: **bản demo** |
| Ngôn ngữ | Tiếng Việt trước, tiếng Anh sau (dựng hệ dịch ngay từ đầu) |
| Thời lượng | Học theo DST: 1 ngày = 8 phút thực; Thu 20, Đông 15, Xuân 20, Hạ 15 ngày |
| PvP | **Không** có |
| Chiêu thức | Tiêu hao chính chỉ số sinh tồn đang có (Thể Lực, Khí Huyết, Đạo Tâm, Đan Độc...) + cooldown. Không có thanh Linh Lực riêng |
| Nhân vật demo | Huyết Mạch Cổ Thú + Thực Hồn Nhân |

---

## 1. Tầm nhìn & Trụ cột thiết kế

**Trải nghiệm cốt lõi:** Một nhóm người xuyên không rơi vào thế giới huyền huyễn hoang dã tạo ngẫu nhiên, trong tay không có gì. Họ tự do đi tìm vùng đất ưng ý để lập Sơn Môn, gom nguyên liệu, chế đồ nghề, sống sót qua 4 mùa và tự kích hoạt Bí Cảnh, Boss và các sự kiện thế lực.

**Bốn nguyên tắc khóa chặt:**
1. **Không rớt đồ sẵn.** Quái và Boss chỉ rơi nguyên liệu thô (Yêu Đan, Tinh Huyết, Lân Giáp, Lõi Cổ Khôi...). Binh khí, đan dược, bùa chú, công trình đều phải tự làm.
2. **Sát thương nén gọn, tiến trình chiều ngang.** Máu và sát thương không phình to theo cấp số nhân. Sức mạnh đến từ năng lực mới, nhánh kỹ năng, Ấn Ký, hiệu ứng tôi luyện và cách khắc chế cơ chế.
3. **Hệ sinh thái tự nhiên kiểu DST.** Yêu thú có tập tính và tương tác với nhau. Thế lực (Tông Môn, Chấp Pháp, thương nhân) chỉ xuất hiện qua sự kiện kích hoạt có điều kiện.
4. **Chế tác dựa trên tài nguyên, có công cụ giảm tải.** Lò và nồi kiểu crockpot. Việc lặp lại (chặt, đào, vận chuyển) được tự động hóa bằng Khôi Lỗi từ giữa game.

### 1.1. Art direction
Tham chiếu hình khối: ảnh chụp một game 3D do chủ dự án cung cấp (2026-11-23), chỉ học cách dựng khối low-poly, không lấy phong cách kiến trúc cổ phong của game đó. Tham chiếu không khí và màu sắc: cảm giác hoang dã, bất an của Don't Starve Together. Không sao chép giao diện hay asset của game nào.
- **Hình khối:** 3D low-poly đến mid-poly, tỉ lệ hơi cách điệu. Cây có tán tròn khối, đá góc cạnh mềm.
- **Chất liệu:** texture tô tay hoặc màu phẳng có chuyển sắc kiểu tranh vẽ, không dùng PBR chân thực.
- **Màu sắc (quy tắc 80/20):** khoảng 80% màn hình là màu đất trầm, độ bão hòa thấp: xanh ô liu, nâu đất, vàng úa, gỉ sắt, tím tro, đá xám ngả nâu. Khoảng 20% còn lại là màu rực, **chỉ dành cho thứ có ý nghĩa gameplay**: lửa, Linh Thạch, linh khí, quả chín, mắt yêu thú, công trình quan trọng. Mỗi biome có bảng màu chủ đạo riêng nhưng đều theo quy tắc này. Bảng màu biome đầu nằm ở [plan asset 3D, phase-01](../plans/261123-1413-3d-asset-pipeline-hunyuan3d-omni/phase-01-style-lock-and-setup.md).
- **Kiến trúc: lạc vào một thế giới lạ, không phải tông môn tu tiên.** Hoang Giới rải rác phế tích của một nền văn minh cổ đã mất: cột đá nguyên khối nghiêng đổ, thanh đá gãy, phù văn phát sáng màu linh khí, mảnh đá lơ lửng, rễ cây và rêu phủ kín. Nét Đông phương chỉ phảng phất (tấm bia, dáng phù văn), không có mái cong, cổng tam quan hay đèn lồng kiểu tông môn. Tham chiếu: `Cổng Hoang Cổ` trong cảnh thử, ảnh `plans/reports/style-test-261123-1434-cong-hoang-co.png`.
- **Công trình Sơn Môn của người chơi:** đồ sinh tồn chắp vá từ gỗ, đá, xương, da, dây thừng. Đồ bậc cao gắn thêm mảnh phế tích nhặt được (đá khắc phù văn, tinh thể Linh Thạch), không phải kiến trúc cổ phong hoàn chỉnh.
- **Ánh sáng và không khí:** thế giới u ám, đè nén. Trời xám đục, chạng vạng cam đục pha xám, đêm gần như đen hẳn, chỉ có vùng lửa sáng ấm. Sương xám dày theo khoảng cách che bớt tầm nhìn. Mép màn hình tối dần (vignette). Bloom nhẹ, chỉ ở nguồn sáng. Hạt bay (đom đóm, tàn lửa, linh khí) là điểm sáng hiếm hoi. Ánh sáng đổi rõ rệt theo ngày, chạng vạng, đêm.
- **Cảnh thử:** `world/style_test/style_test.tscn`, ảnh tại `plans/reports/style-test-261123-1429-canh-thu-u-am.png`.
- **Camera:** góc nghiêng phối cảnh (perspective), thấp hơn kiểu DST một chút để thấy được bầu trời và chiều cao công trình.
- **Thủy mặc chỉ còn làm điểm nhấn:** chữ thư pháp lớn khi vào vùng hoặc kích hoạt kỹ năng, viền mực khi Tâm Ma, khung giao diện.
- **Giao diện:** khung viền vàng đồng, nền tối trong suốt, biểu tượng tròn.

---

## 2. Bối cảnh

- Nhân vật là **người xuyên không**, tỉnh dậy ở Hoang Giới với hai bàn tay trắng.
- Mỗi người mang theo **Thiên Thư**, chính là wiki trong game. Thiên Thư chứa sẵn công thức. Món nào chế thành công thì được "kích hoạt" (đánh dấu đã chế) trên Thiên Thư của cả nhóm.
- Thế giới không chào đón người lạ. Tông Môn bản địa coi người xuyên không là dị số, nên Chấp Pháp truy bắt khi người chơi gây Nghiệp lớn.
- Chưa có cái kết. Hướng mở rộng về sau, có thể có: Cổng Hồi Quy (về lại thế giới cũ).

---

## 3. Vòng lặp gameplay

**Nhịp ngắn: Ngày, Chạng vạng, Đêm**
- Ngày: dò bản đồ, kiếm ăn, chặt cây, đào quặng, múc Linh Thủy.
- Chạng vạng: về Sơn Môn hoặc dựng lửa trại, nấu Linh Thực, chuẩn bị nguồn sáng.
- Đêm: giữ lửa hoặc Đèn Dẫn Hồn để tránh tụt Đạo Tâm và quái bóng tối, hoặc đi săn sinh vật chỉ xuất hiện về đêm.

**Nhịp trung: 4 mùa và mở rộng Sơn Môn**
- Tích trữ, chế đồ chống lạnh, chống mưa, chống nóng. Nâng cấp công trình. Chế Khôi Lỗi.

**Nhịp dài: Thức Tỉnh và sự kiện kích hoạt**
- Thức Tỉnh nhân vật, kích hoạt Cổ Đàn, vào Bí Cảnh, hạ Boss, xử lý sự kiện Nhân Quả.

---

## 4. Thế giới & Biome

**Tạo bản đồ:** Mỗi thế giới mới thay đổi vị trí, diện tích và cách nối các biome. Nên ghép từ các mảnh đặt sẵn (kiểu DST) thay vì noise thuần, để bảo đảm mỗi biome luôn đủ 5 lớp tài nguyên. Các vùng nối nhau qua địa hình, đường đá cổ và Cổ Truyền Tống Trận.

**Mỗi biome đủ 5 lớp:** thức ăn, cây gỗ, đá/quặng, vật liệu lặt vặt, yêu thú có tập tính riêng. Mỗi biome có **một loại Linh Tuyền** (xem mục 5).

| Biome | Thức ăn & thực vật | Cây & khoáng vật | Yêu thú & tập tính | Môi trường |
|---|---|---|---|---|
| **Rừng Linh Trúc & Đồng Cỏ** | Bụi linh quả, nấm trắng, củ hoang; thỏ linh, trĩ rừng chạy theo bầy | Linh trúc (mọc lại nhanh), gỗ thường; đá tảng, quặng Linh Thạch sơ cấp | Khỉ linh nhặt trộm đồ rơi; bầy sói săn lúc chạng vạng và đêm | Cân bằng, dễ kiếm ăn sớm, thiếu khoáng bậc cao |
| **U Minh Đầm Lầy** | Nấm dạ quang, rễ thủy sinh, cá/cua đầm, Âm Hồn Thảo | Cây mục (nhựa, gỗ ẩm), lau sậy; đá rêu, Chu Sa, quặng âm khí | Đỉa linh hút khí huyết, quạ ăn xác, Cương Thi/U Linh trồi lên từ mộ cổ khi tối | Sương độc tụt Đạo Tâm, bùn làm chậm; giàu Chu Sa và thảo dược |
| **Xích Viêm Hỏa Sơn** | Quả hỏa bụi, trứng dị điểu, thịt thú chịu nhiệt, Hỏa Liên | Cây cháy xém (than, gỗ chịu lửa); bazan, Huyền Thiết Tinh, Nham Tinh | Thằn lằn nham phun lửa tự vệ; chim lửa làm tổ trên vách cao | Nóng quanh năm, dễ bén lửa; nguồn kim loại tốt nhất |
| **Lôi Trì Thạch Cốc** | Rêu điện quang, dơi hang, thú gặm nhấm | Tùng cổ thụ (gỗ bền); thạch anh, Lôi Tinh Thạch, cổ kiếm gãy | Linh thú hệ Lôi đi theo cặp, nhanh; thạch khôi lỗi ngủ say cạnh trụ đá | Sét đánh ngẫu nhiên, cắm Trụ Dẫn Lôi để thu hoặc tránh |
| **Hàn Băng Tuyết Lĩnh** | Cá dưới băng, rêu tuyết, thú lông dày, Tuyết Liên | Tùng tuyết; băng khối, Vạn Năm Huyền Băng | Băng lang săn theo đàn; gấu tuyết ngủ đông, chỉ tỉnh khi bị đánh thức hoặc nghe tiếng động lớn | Rét quanh năm; tốt để trữ thực phẩm và lấy vật liệu kháng nhiệt |
| **Hoang Cổ Di Tích** | Quả dại cổ thụ, nấm tàn tích, thú hoang ẩn trong phế tích | Dây leo cổ; gạch đá chạm khắc, Tinh Thể Cổ Văn | Cơ quan thú tuần tra quanh bệ đá; linh thể canh di tích về đêm | Bẫy sàn cổ; nhiều nguyên liệu Thức Tỉnh |

---

## 5. Linh Tuyền

Mỗi biome có một loại Linh Tuyền. Người chơi múc nước bằng bình rồi dùng vào **4 việc**. Linh Tuyền **không** ảnh hưởng cách đặt công trình, **không** hút yêu thú, **không** ảnh hưởng người chơi khác.

| Linh Tuyền | Tưới cây | Tôi luyện vũ khí | Ngâm mình / uống | Dung môi lò đan |
|---|---|---|---|---|
| **Thanh Mộc Tuyền** (Rừng) | Cây ra quả nhanh, có tỉ lệ ra Linh Quả biến dị | **Sinh Cơ:** mỗi đòn hồi chút Khí Huyết | Hồi Khí Huyết chậm | Tăng tỉ lệ đan trị liệu |
| **U Minh Âm Tuyền** (Đầm Lầy) | Mọc Âm Hồn Thảo, nấm dạ quang | **Phá Hồn:** đánh trúng linh thể và ma | Thấy linh thể một lúc, tụt Đạo Tâm | Tăng tỉ lệ đan Đạo Tâm |
| **Xích Viêm Dung Tuyền** (Hỏa Sơn) | Không tưới được (cây cháy) | **Thiêu Đốt:** đốt cháy mục tiêu | Giữ ấm lâu | Tăng tỉ lệ đan kháng lạnh |
| **Lôi Trì Thủy** (Thạch Cốc) | Cây lớn ngay, nhưng có thể héo chết | **Lôi Kích:** thỉnh thoảng gây choáng | Tăng tốc chạy ngắn hạn | Tăng tỉ lệ đan tốc độ |
| **Huyền Băng Tuyền** (Tuyết Lĩnh) | Cây chịu nóng mùa Hạ, quả lâu hỏng | **Hàn Băng:** làm chậm mục tiêu | Mát người | Tăng tỉ lệ đan kháng nóng |
| **Cổ Văn Tuyền** (Di Tích) | Ra quả ngẫu nhiên, có thể ra loại hiếm | **Tẩy Luyện:** xóa hiệu ứng tôi cũ | Không có tác dụng | Tăng nhẹ tỉ lệ mọi loại đan |

**Luật:**
- **Một vũ khí chỉ mang một hiệu ứng tôi** tại một thời điểm. Hiệu ứng dùng được N đòn rồi hết, nhúng lại để nạp. Không cộng dồn.
- **Linh Thủy mất linh tính sau vài ngày** trong bình thường. Bình bùa giữ được lâu hơn.
- **Cây tưới loại nước khác nhau ra biến thể nguyên liệu khác nhau.** Ví dụ Linh Mễ tưới Băng Tuyền thành Hàn Mễ (ăn vào mát người). Biến thể là nguyên liệu riêng cho nồi nấu và lò đan.
- Áo giáp **chưa** tôi được bằng Linh Thủy ở bản này.

---

## 6. Chế tác

### 6.0. Nền sinh tồn kiểu DST (bắt buộc có từ demo)
- **Lượm tài nguyên bằng tay:** cành khô, cỏ/sợi, đá lửa, quả, nấm, củ nằm trên mặt đất hoặc trên bụi. Bụi cây ra quả lại sau vài ngày.
- **Công cụ phải tự chế:** Rìu (chặt cây), Cuốc (đào đá, quặng), Xẻng (đào gốc, bứng bụi cây về trồng), Giáo hoặc gậy (đánh), Đuốc (nguồn sáng cầm tay).
- **Độ bền:** công cụ, vũ khí, đuốc đều hao mòn theo số lần dùng và hỏng khi hết.
- **Chặt cây:** cây chịu nhiều nhát rìu, đổ xuống rơi gỗ, để lại gốc. Gốc đào bằng xẻng ra thêm gỗ. Có thể trồng lại cây từ hạt hoặc quả thông. Linh trúc mọc lại nhanh.
- **Đào khoáng:** tảng đá chịu nhiều nhát cuốc, vỡ dần theo từng giai đoạn, rơi đá, đá lửa, quặng.
- **Bậc chế tác:** đứng gần **Bàn Chế Tác** mới mở được công thức bậc 2. Tầm mở khóa giống máy khoa học của DST.
- **Lửa trại:** nguồn sáng và sưởi, nướng đồ ăn, cần thêm nhiên liệu (gỗ, cỏ, cành) để không tắt.
- **Rơi và nhặt đồ:** đồ thả xuống đất nằm lại trong thế giới, ai cũng nhặt được (khỉ linh cũng nhặt).

### 6.1. Bốn tầng nguyên liệu
1. **Sinh tồn nền:** gỗ, linh trúc, đá, cỏ/sợi, da lông, thịt/quả/nấm.
2. **Khoáng vật & tinh thể:** Linh Thạch, Huyền Thiết Tinh, Lôi Tinh Thạch, Huyền Băng.
3. **Dược thảo & vật liệu bùa:** Linh Thảo, Âm Hồn Thảo, Hỏa Liên, Tuyết Liên, Chu Sa, giấy bùa.
4. **Tinh hoa dị giới:** Yêu Đan, Tinh Huyết Boss, Lõi Cổ Khôi, nguyên liệu Boss đặc trưng.

### 6.2. Thẻ thuộc tính nguyên liệu
Mỗi nguyên liệu mang một hoặc vài **thẻ** kèm giá trị, ví dụ: Mộc, Hỏa, Thủy, Âm, Lôi, Băng, Thú, Ngư, Quả, Linh, Độc. Công thức của nồi nấu và lò đan đòi **giá trị tối thiểu/tối đa** của các thẻ, giống crockpot. Mỗi công thức có độ ưu tiên; khi nhiều công thức cùng khớp thì chọn công thức ưu tiên cao nhất.

### 6.3. Nồi Linh Thực (sống qua ngày)
- 4 ô, đủ nguyên liệu khớp công thức là ra món. Luôn thành công; không khớp công thức nào thì ra **món cháy** (vẫn ăn được, rất kém).
- Vai trò: no bụng, hồi chậm, buff nhẹ kéo dài.

### 6.4. Lò Đan (giải quyết vấn đề cụ thể)
- 4 ô nguyên liệu + 1 ô dung môi (Linh Thủy, không bắt buộc).
- **Tỉ lệ thành công = tỉ lệ gốc của công thức + bậc lò + dung môi hợp hệ.**
- **Thất bại ra Phế Đan.** Phế Đan dùng làm phân bón ruộng Linh Thảo.
- Lần đầu thành công thì Thiên Thư đánh dấu công thức đã chế.
- Không mini-game, không canh lửa.

### 6.5. Đan dược: 7 nhóm chức năng

| Nhóm | Ví dụ | Giải quyết việc gì |
|---|---|---|
| Cấp cứu | Hồi Huyết Đan | Hồi máu ngay giữa trận (đồ ăn không làm được) |
| Kháng môi trường | Ôn Dương Đan (lạnh), Thanh Lương Đan (nóng), Tị Độc Đan (sương độc), Tị Thủy Đan (mưa) | Sống qua mùa khắc nghiệt và biome độc |
| Đạo Tâm | Định Thần Đan | Kéo Đạo Tâm lên nhanh, xua Tâm Ma |
| Năng lực tạm thời | Dạ Thị Đan, Khinh Thân Đan, Quy Tức Đan (ẩn khí tức) | Mở khả năng trong thời gian ngắn |
| Khắc chế Boss | Phá Chướng Đan (thấy U Minh Quỷ Tướng trong sương) | Cần nguyên liệu Boss, dùng đúng trận |
| Thức Tỉnh | Đan Thức Tỉnh từng tầng | Lễ vật bắt buộc trong nghi thức Thức Tỉnh |
| Hồi sinh | Hoàn Hồn Đan | Hồi sinh đồng đội đang là Hồn Phách |

**Đan Độc (chống lạm dụng):**
- Mỗi viên đan cộng Đan Độc. Vượt ngưỡng thì bị debuff (buồn nôn, tụt Đạo Tâm, chậm hồi).
- Đan Độc tự giảm theo ngày, giảm nhanh hơn khi ăn một số Linh Thực.
- Thực Hồn Nhân có ngưỡng Đan Độc riêng (xem mục 9).

### 6.6. Bùa chú
- Bàn Vẽ Phù vận hành như công thức cố định: đủ nguyên liệu (giấy bùa, Chu Sa, nguyên liệu hệ) là ra, có tỉ lệ thành công.
- Ví dụ: Định Thân Phù, Hàn Băng Phù, Khai Nhãn Phù, Quỷ Diện (ngụy trang khí tức).
- Mùa Xuân: bùa giấy để ngoài rương bùa sẽ ẩm và hỏng dần.

### 6.7. Công trình Sơn Môn
- **Hậu cần:** Bếp lửa, Nồi Linh Thực, Rương bùa (chống cháy, chống trộm), Ruộng Linh Thảo, Đèn Dẫn Hồn, Trụ Chiếu Sáng.
- **Chế tác:** Lò Đan, Bàn Vẽ Phù, Đài Luyện Khí (rèn binh khí, giáp, lắp Khôi Lỗi).
- **Nghi thức:** Trận Bàn Thức Tỉnh (nơi làm nghi thức Thức Tỉnh và chịu Thiên Kiếp), Hồi Hồn Đài.
- **Sự kiện:** Đài Dẫn Khách / Thắp Hương Tín Hiệu (mời thương nhân, tán tu).
- Công trình đặt tự do, không có luật kề nhau.

### 6.8. Khôi Lỗi & Pháp Trận (tự động hóa)
- **Khôi Lỗi Lao Động:** cắm cọc khoanh vùng, Khôi Lỗi tự chặt cây, đào đá và chở về rương.
- **Pháp Trận:** Thủy Dẫn Trận tự tưới ruộng (có thể nạp Linh Thủy để tưới ra biến thể).
- **Giới hạn:** Khôi Lỗi ăn Linh Thạch theo thời gian, đi chậm, dễ hỏng khi gặp quái mạnh, không làm được nghi thức hay đánh Boss.

---

## 7. Sinh tồn

### 7.1. Ba chỉ số
- **Khí Huyết:** mất khi trúng đòn, bỏng, cóng, Đan Độc quá ngưỡng, Thiên Kiếp.
- **Thể Lực:** giảm theo thời gian, phải ăn đều. Thấp thì chậm và yếu đi.
- **Đạo Tâm:** giảm khi ở trong bóng tối, dầm mưa, hít sương độc, dùng cấm thuật, đứng gần quái đáng sợ. Đạo Tâm thấp thì nhìn thấy linh thể và ẩn họa, nhưng Tâm Ma xuất hiện.

### 7.2. Tâm Ma
- Đạo Tâm dưới ngưỡng thì Tâm Ma xuất hiện và tấn công thật.
- **Dấu hiệu nhận biết bắt buộc:** viền màn hình nhòe mực, âm thanh thì thầm, Tâm Ma có nét vẽ khác hẳn quái thường. Người chơi luôn biết mình đang gặp Tâm Ma.

### 7.3. Nhiệt độ
- Thân nhiệt chịu ảnh hưởng của mùa, biome, nguồn nhiệt, đồ mặc, đan và Linh Thủy (Xích Viêm giữ ấm, Huyền Băng làm mát).

### 7.4. Bốn mùa (bắt đầu từ mùa Thu)

| Mùa | Đặc điểm | Cần chuẩn bị |
|---|---|---|
| **Thu** (khởi đầu) | Ôn hòa, ngày dài đêm ngắn | Dò bản đồ, chọn đất, tích trữ |
| **Đông** | Đêm rất dài, rét, mặt nước đóng băng, ra chiêu chậm | Áo lông, hỏa lô cầm tay, Ôn Dương Đan, Xích Viêm Thủy |
| **Xuân** | Mưa dầm, Đạo Tâm tụt nhanh, bùa giấy ẩm hỏng, yêu thú Thủy/Mộc và nấm độc nhiều | Ô/áo chống mưa, Rương bùa, Định Thần Đan, Tị Thủy Đan |
| **Hạ** | Nóng gắt, say nắng, công trình và cây dễ tự bốc cháy | Băng khối, Thủy Dẫn Trận, Thanh Lương Đan, Huyền Băng Thủy |

**Thời lượng (học theo DST, chỉnh được khi tạo thế giới):**
- **1 ngày = 8 phút thực**, chia 16 phần, mỗi phần 30 giây. Mỗi phần thuộc Ngày, Chạng vạng hoặc Đêm.
- **Độ dài mùa mặc định:** Thu 20 ngày, Đông 15 ngày, Xuân 20 ngày, Hạ 15 ngày. Một năm 70 ngày.
- **Tỉ lệ Ngày / Chạng vạng / Đêm thay đổi theo mùa** (số phần trên 16):

| Mùa | Ngày | Chạng vạng | Đêm |
|---|---|---|---|
| Thu | 8 | 6 | 2 |
| Đông | 5 | 5 | 6 |
| Xuân | 5 | 8 | 3 |
| Hạ | 11 | 1 | 4 |

- Game báo trước vài ngày khi sắp đổi mùa.

---

## 8. Tiến trình: Thức Tỉnh Bản Nguyên

Không có cảnh giới. Mỗi nhân vật có tiến trình riêng.

### 8.1. Ba tầng Thức Tỉnh
**Sơ Tỉnh, Trung Tỉnh, Toàn Tỉnh.** Mỗi tầng:
- Cho **điểm kỹ năng** để mở nhánh trên cây kỹ năng riêng của nhân vật.
- Mở thêm **một ô Ấn Ký** (tối đa 3 ô).
- Chỉ tăng nhẹ chỉ số nền (giữ nguyên tắc sát thương nén gọn).

### 8.2. Cây kỹ năng
- Mỗi nhân vật có cây kỹ năng riêng, có các **nhánh loại trừ nhau**. Chọn nhánh này thì khóa nhánh kia.
- Ví dụ Huyết Mạch Cổ Thú: nhánh **Hóa Thú** (bạo phát mạnh hơn, cuồng tính nặng hơn) hoặc nhánh **Thú Giác** (dò tài nguyên xa hơn, dễ thuần thú).
- Hai người cùng chơi một nhân vật vẫn có lối chơi khác nhau.

### 8.3. Ấn Ký
- Làm từ nguyên liệu Boss tại Đài Luyện Khí.
- Mỗi Ấn Ký **đổi một cơ chế**, không cộng chỉ số. Ví dụ Ấn Quỷ Tướng: đứng trong bóng tối không tụt Đạo Tâm.
- Tháo ra lắp vào được, nên Ấn Ký là lựa chọn thay ngang.

### 8.4. Nghi thức Thức Tỉnh: Kiếp Nạn và Thiên Kiếp cùng lúc
**Điều kiện:** đủ Yêu Đan theo tầng + Đan Thức Tỉnh tầng đó + đứng trên Trận Bàn Thức Tỉnh ở Sơn Môn.

**Diễn biến (một sự kiện, ba mặt trận cùng lúc):**
1. **Thiên Kiếp:** sét từ trời đánh thành đợt vào khu vực quanh người thức tỉnh. Có vùng cảnh báo trước khi sét giáng. Trụ Dẫn Lôi dựng sẵn hút bớt một phần số tia sét.
2. **Kiếp Nạn riêng của nhân vật:** người thức tỉnh phải vượt một thử thách theo bản chất nhân vật (mục 9), cùng lúc với việc né sét.
3. **Yêu thú kéo tới:** khí tức bùng lên kéo các đợt yêu thú trong vùng lân cận. Đồng đội hộ pháp: chặn quái, tiếp đan, giữ đèn và lửa.

**Kết quả:**
- Sống qua đủ số đợt thì thức tỉnh thành công.
- Người thức tỉnh chết giữa chừng thì nghi thức thất bại, mất lễ vật (Yêu Đan, Đan Thức Tỉnh), về trạng thái Hồn Phách như chết bình thường.

---

## 9. Nhân vật Dị Nhân

Mỗi nhân vật có năng lực đặc trưng đi kèm cái giá, và có Kiếp Nạn riêng khi Thức Tỉnh.

| Nhân vật | Năng lực | Cái giá | Kiếp Nạn khi Thức Tỉnh |
|---|---|---|---|
| **Thực Hồn Nhân** | Nuốt trực tiếp Yêu Đan, tinh hoa quái, dị thảo để có hiệu ứng tạm thời và hồi nhanh. Ngưỡng Đan Độc cao hơn người thường | Nuốt bừa thì nhiễm tạp khí, xung đột thuộc tính, phản phệ Đạo Tâm và Khí Huyết. Vượt ngưỡng Đan Độc thì phản phệ nặng hơn người thường | Phải nuốt và "tiêu hóa" tinh hoa trong khi Đan Độc liên tục tăng, không được vượt ngưỡng |
| **Huyết Mạch Cổ Thú** (Bán Yêu) | Cảm nhận dấu vết thú và tài nguyên từ xa, cận chiến khỏe, hóa thú khi nguy cấp | Chịu ảnh hưởng mạnh của chu kỳ trăng và thời tiết, dễ cuồng tính khi đói hoặc Đạo Tâm thấp | Cuồng tính dâng lên, phải giữ không mất kiểm soát (không đánh nhầm đồng đội) |
| **Ngự Khí & Khôi Lỗi Sư** | Chế Khôi Lỗi, bùa, trận tốn ít nguyên liệu hơn; điều khiển rối chiến đấu từ xa | Cơ thể yếu, hồi phục chậm, phụ thuộc đồ nghề | Phải giữ các Khôi Lỗi hộ thân sống sót dưới sét và quái |
| **Âm Dương Thể** | Giữ Đạo Tâm trong ngưỡng ranh giới thì nhìn xuyên ẩn họa, lướt bóng tối, ra chiêu dị biệt | Trượt khỏi ngưỡng là Tâm Ma kích hoạt ngay | Đạo Tâm dao động mạnh, phải giữ trong ngưỡng ranh giới đến hết nghi thức |

Demo và vertical slice làm 2 nhân vật: **Huyết Mạch Cổ Thú** và **Thực Hồn Nhân**.

### 9.1. Chiêu thức tiêu hao gì
Không có thanh Linh Lực riêng. Mỗi chiêu tiêu hao **chính các chỉ số sinh tồn** phù hợp với bản chất của nó, kèm **cooldown**:

| Loại chiêu | Tiêu hao | Ví dụ |
|---|---|---|
| Chiêu thể chất (lướt, đòn nặng) | Thể Lực (đói nhanh hơn) | Huyết Mạch: Hóa Thú tốn nhiều Thể Lực và đói nhanh suốt thời gian hóa thú |
| Chiêu nuốt, hấp thụ | Đan Độc / tạp khí tăng | Thực Hồn Nhân: nuốt Yêu Đan lấy năng lực tạm thời, đổi lại Đan Độc tăng |
| Chiêu điều khiển đồ nghề | Nguyên liệu (Linh Thạch, giấy bùa) | Khôi Lỗi Sư: triệu rối chiến đấu tốn Linh Thạch |
| Chiêu bóng tối, cấm thuật | Đạo Tâm (đôi khi cả Khí Huyết) | Âm Dương Thể: lướt bóng tối tốn Đạo Tâm |

Nguyên tắc: dùng chiêu luôn có cái giá đè lên vòng sinh tồn, nên người chơi phải chọn lúc dùng.

---

## 10. Combat

- **Sát thương nén gọn:** chỉ tăng nhẹ qua mỗi tầng Thức Tỉnh.
- **Sức mạnh thật** đến từ: nhánh kỹ năng, Ấn Ký, hiệu ứng tôi luyện vũ khí, đan năng lực tạm thời, bùa và trận khắc chế.
- **Boss cơ chế** (mỗi Boss rơi nguyên liệu đặc trưng, chỉ làm được vài món nhất định):

| Boss | Cơ chế | Cách khắc chế |
|---|---|---|
| **U Minh Quỷ Tướng** (đêm, đầm lầy) | Miễn sát thương vật lý trong sương | Rọi Đèn Dẫn Hồn để ép hiện hình; vũ khí tôi Phá Hồn; Phá Chướng Đan |
| **Xích Viêm Hỏa Lang** (hỏa sơn) | Tỏa nhiệt đốt đồ, gọi mưa lửa | Đứng trong Thủy Trận, ném Hàn Băng Phù để ngắt chiêu; vũ khí tôi Hàn Băng |
| **Huyền Thiết Nham Quy** (hang đá) | Mai phản đòn tầm xa | Dụ húc vào trụ Lôi Thạch dựng sẵn để nứt giáp |

---

## 11. Chết & Hồi sinh (bản đơn giản)

- **Chết:** rơi toàn bộ đồ tại chỗ, thành **Hồn Phách**. Hồn Phách bay tự do, không nhặt đồ, không đánh.
- **Hồi sinh** bằng một trong hai cách:
  - Đồng đội dùng **Hoàn Hồn Đan** lên Hồn Phách.
  - Hồn Phách bay về **Hồi Hồn Đài** ở Sơn Môn. Công trình tốn nguyên liệu để dựng, mỗi lần dùng tốn thêm.
- **Cái giá:** mỗi lần hồi sinh, Khí Huyết tối đa giảm 25%, cộng dồn tối đa 2 lần. Phần mất hồi lại khi ngủ hoặc ăn Linh Thực đặc biệt.
- **Cả nhóm chết hết và không còn cách hồi sinh:** theo tùy chọn chọn lúc tạo thế giới:
  - **Reset:** tạo thế giới mới.
  - **Chơi tiếp:** cả nhóm hồi sinh tại điểm xuất phát hoặc Hồi Hồn Đài, thế giới giữ nguyên, nhận mức phạt Khí Huyết tối đa.

---

## 12. Nhân Quả & Sự kiện kích hoạt

### 12.1. Hai thanh Nhân Quả (chung cho cả nhóm)
- **Nghiệp:** tăng khi phá cấm chế, đào mỏ có ấn ký Tông Môn, dùng cấm thuật, săn linh thú hiền.
- **Duyên:** tăng khi trả lễ Cổ Đàn, giúp tán tu, thả linh thú, trồng linh thụ.

### 12.2. Ngưỡng và nhóm sự kiện
Mỗi khi chạm ngưỡng, game rút **một** sự kiện từ nhóm tương ứng. Mỗi nhóm có cả cơ hội lẫn hiểm họa.

| Ngưỡng | Nghiệp | Duyên |
|---|---|---|
| 30 | Thương nhân chợ đen bán cấm phẩm **(cơ hội)** · Oán linh quấy rối ban đêm **(hiểm họa)** | Tán tu nhờ việc, đưa đủ đồ thì được thưởng **(cơ hội)** · Kẻ ăn xin trộm đồ trong rương **(hiểm họa)** |
| 60 | Đội Chấp Pháp tuần tra tới **(hiểm họa)** · Tà tu mời hợp tác, tặng công thức cấm **(cơ hội)** | Linh thú quy thuận / Cổng Bí Cảnh mở sớm **(cơ hội)** · Tin đồn bảo vật kéo đám tán tu tới tranh giành **(hiểm họa)** |
| 100 | Lệnh truy nã: Chấp Pháp tinh nhuệ tới, Tâm Ma tăng | "Khí vận quá vượng": tà tu tới cướp khí vận, thắng thì được báu vật lớn |
| Cả hai cao | Nhóm sự kiện lai riêng, ví dụ một nhân vật nửa chính nửa tà xuất hiện | (chung) |

### 12.3. Luật chống cứng nhắc
- **Sự kiện xảy ra thì tiêu hao điểm** của thanh tương ứng.
- **Cả hai thanh tự giảm dần** theo thời gian.
- **Hiển thị rõ:** mây lành hoặc mây đen trên Sơn Môn, kèm số và ngưỡng trên giao diện.

### 12.4. Các sự kiện khác
- **Thiên tượng & chu kỳ:** Huyết Nguyệt / Triều Cường Linh Khí (quái cuồng bạo nhưng rơi tinh hoa, mỏ hiếm phát sáng). Cổng Bí Cảnh ngầm chỉ mở vào đêm trăng tròn, bão sét lớn hoặc sương dày theo mùa; bên trong là phó bản giải đố và thủ vệ.
- **Cổ Đàn:** đặt đủ lễ vật hoặc Yêu Đan thì triệu hồi thử thách hoặc Boss khu vực.
- **Do người chơi gọi:** Đài Dẫn Khách mời thương nhân, tán tu ghé 1 ngày đêm.
- **Tiến trình nội tại:** nghi thức Thức Tỉnh (mục 8.4).

---

## 13. Co-op & Cân bằng

- 1–4 người, **thiết kế và cân bằng cho 4 người, theo kiểu DST**: thế giới và quái không co giãn mạnh theo số người; nhóm đông thì làm được nhiều việc cùng lúc, nhóm ít người thì phải chọn việc ưu tiên.
- Nhân Quả, Thiên Thư (wiki) và tùy chọn thế giới dùng chung cho cả nhóm.
- **Không có PvP.** Đòn đánh không gây sát thương lên đồng đội. Ngoại lệ duy nhất, giữ làm đặc trưng nhân vật: Huyết Mạch Cổ Thú mất kiểm soát trong Kiếp Nạn hoặc khi cuồng tính có thể đánh trúng đồng đội.
- **Mạng: một người chơi làm host** (listen server), host có quyền quyết định trạng thái thế giới. Phải xây từ ngày đầu.
  - Demo: kết nối trực tiếp qua IP hoặc LAN (Godot high-level multiplayer + ENet).
  - Bản phát hành: chuyển sang Steam P2P (GodotSteam) để người chơi không phải mở port.

---

## 14. Lộ trình sản xuất

1. **Style Bible & quy trình asset:** chốt camera nghiêng cố định, phong cách tô màu kiểu tranh vẽ theo mục 1.1, tỉ lệ nhân vật, cây đá, công trình, quái. Dùng AI render concept và texture tham chiếu cho 2 biome đầu. Model 3D vẫn dựng hoặc chỉnh tay để giữ đồng bộ. Nhớ khai báo nội dung AI khi lên Steam.
2. **Prototype / Demo đầu (đề xuất 4–8 tuần):** 1 biome, 1 nhân vật, ngày đêm, Thể Lực và Đạo Tâm, Nồi Linh Thực, Lò Đan, 1 loại Linh Tuyền, 1 loài yêu thú, **2 người chơi qua mạng ngay từ đầu**.
3. **Vertical slice:** 2 biome liền kề (Rừng Linh Trúc + U Minh Đầm Lầy) đủ 5 lớp sinh thái, 2 Linh Tuyền, 3 chỉ số, ngày đêm, chuyển mùa Thu sang Đông, 2 nhân vật có Thức Tỉnh tầng 1 (gồm nghi thức Thiên Kiếp + Kiếp Nạn), các công trình Bếp, Rương, Lò Đan, Bàn Phù, Hồi Hồn Đài, 1 Khôi Lỗi vận chuyển, 3 loài yêu thú, thanh Nhân Quả với ngưỡng 30, 1 Boss (U Minh Quỷ Tướng).
4. **Test co-op 2–4 người:** cảm giác điều khiển, độ mượt mạng, tốc độ tụt chỉ số, nhịp chế tác, cân bằng đánh Boss.
5. **Mở rộng theo gói nội dung:** 4 biome còn lại, đủ 4 mùa, 2 nhân vật còn lại, Thức Tỉnh tầng 2–3, Bí Cảnh, các ngưỡng Nhân Quả 60/100, thêm Boss.

---

## 15. Công nghệ & Ngôn ngữ

- **Engine:** Godot 4, viết bằng GDScript. Scene và resource ở dạng text (`.tscn`, `.tres`), dễ cho AI đọc, sửa và so sánh thay đổi.
- **Dữ liệu tách khỏi code:** nguyên liệu, thẻ thuộc tính, công thức, yêu thú, sự kiện Nhân Quả đặt trong file dữ liệu. Thêm nội dung không cần sửa code.
- **Ngôn ngữ:** tiếng Việt trước. Mọi chữ hiển thị đi qua khóa dịch (hệ translation của Godot) ngay từ đầu, để thêm tiếng Anh sau mà không phải sửa lại.

## 16. Câu hỏi chưa chốt

1. Tên chính thức của game (đang chọn trong danh sách gợi ý).
2. Mốc thời gian cho bản demo.
