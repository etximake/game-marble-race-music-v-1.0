# 11 - Puzzle Modes Rules (Circle Puzzle & Polygon Puzzle)

## 1. Mục tiêu

Tài liệu này mô tả chi tiết quy tắc hoạt động, thiết kế giao diện và cơ chế hoạt động của hai chế độ chơi đố vui âm nhạc: `circle_puzzle` (arena tròn) và `polygon_puzzle` (arena đa giác). 

Các chế độ chơi này kết hợp cơ chế nảy bóng tạo nhạc với yếu tố game đoán tên bài hát trực quan thông qua đĩa nhạc vinyl (Album Art) lật mở từng phần theo tiến trình bài hát.

---

## 2. Cấu trúc Giao diện & Trật tự Z-Index (Visual Depth Layout)

Để tạo hiệu ứng chiều sâu không gian bắt mắt cho video Shorts, các thành phần giao diện của chế độ Puzzle được sắp xếp theo các phân lớp Z-Index nghiêm ngặt:

1. **Phông nền & Đấu trường (ArenaView)**: `z_index = 0`.
2. **Vệt bóng (TrailRenderer)**: `z_index = 1`. Vệt phát sáng chuyển từ màu nóng sang lạnh sẽ chui luồn bên dưới đĩa than.
3. **Đĩa nhạc trung tâm (PuzzleGridOverlay)**: `z_index = 2`. Đĩa nhạc vinyl đường kính 640px nằm cố định ở tâm đấu trường (Y=1080).
4. **Quả bóng di chuyển (BallView)**: `z_index = 5`. Nổi lên trên cùng, lăn trên bề mặt đĩa than và đấu trường.
5. **Thanh tiến trình (PuzzleProgressBar)**: Căn giữa ở đáy màn hình (Y=1680).

---

## 3. Quy tắc hoạt động của Đĩa nhạc Vinyl (PuzzleGridOverlay)

Đĩa nhạc vinyl là linh hồn của chế độ đố vui đoán bài hát, hoạt động theo các cơ chế sau:

* **Thiết kế**: Gồm phần viền đĩa đen bóng vẽ các đường rãnh vinyl grooves đồng tâm siêu mảnh và phần nhãn đĩa tròn trung tâm hiển thị Album Art (đường kính 560px).
* **Hiệu ứng xoay (Spin Effect)**: Nhãn đĩa than tự động xoay tròn nhẹ nhàng liên tục với tốc độ 15 độ mỗi giây (`spin_angle += deg_to_rad(15.0) * delta`) để tạo cảm giác đĩa nhạc đang phát ở runtime.
* **Cơ chế che phủ và lật mở chớp hé tạm thời (Spatial Twinkling / Flash Hints)**:
  - Nhãn đĩa Album Art được chia thành `REVEAL_SLICES = 8` mảnh hình quạt đồng đều.
  - Ban đầu, tất cả các mảnh được che phủ hoàn toàn bởi màu tối đậm tuyệt đối (`Color(0.05, 0.05, 0.07, 1.0)`).
  - Khi quả bóng va chạm biên (`ball_collided` nhận tại Y = 1080), góc va chạm tương đối so với tâm đĩa than được quy đổi sang hệ tọa độ cục bộ của đĩa nhạc đang xoay:
    ```gdscript
    var local_angle = wrapf(collision_angle - spin_angle, 0.0, TAU)
    var center_slice = int(local_angle / slice_angle) % REVEAL_SLICES
    ```
  - Thay vì lật mở vĩnh viễn làm lộ đáp án sớm, mảnh ghép tại góc va chạm sẽ **chớp hé sáng lên** rồi tự động mờ dần về trạng thái tối trong một khoảng thời gian ngắn:
    - **Phase 1 (Intro)**: Chớp hé **1 mảnh** (`center_slice`), thời gian mờ dần dài `0.45` giây giúp người xem bắt đầu làm quen và tò mò.
    - **Phase 2 (Build-up)**: Chớp hé **2 mảnh** (`center_slice` và mảnh kế tiếp), thời gian mờ dần `0.35` giây.
    - **Phase 3 (Final Storm)**: Chớp hé **3 mảnh** (`center_slice` và 2 mảnh lân cận), thời gian mờ dần cực nhanh `0.22` giây để các mảnh ghép chớp tắt liên tục theo tiết tấu nhạc dồn dập.
  - **Lớp phủ Neon Tint**: Trong 30% thời gian đầu tiên của cú chớp nháy (khi độ sáng mạnh nhất), một lớp màu neon trùng khớp với màu bóng/vệt bóng được phủ đè lên mảnh ghép giúp hiệu ứng chớp sáng vô cùng sống động.
  - **Hé lộ hoàn toàn (Final Reveal)**: Khi thời gian chạy chạm mốc `reveal_time` (mặc định là `duration - 6.0` giây), toàn bộ 8 mảnh ghép sẽ được mở hoàn toàn (`reveal_all`), hé lộ hoàn chỉnh ảnh bìa bài hát không còn che phủ.
* **Hiệu ứng hoàn thành (Complete Glow)**: Khi toàn bộ đĩa nhạc được hé lộ, một vòng sáng neon đổi màu liên tục chạy bao quanh đĩa than (`show_glow = true` trong 1.0 giây).

---

## 4. Thanh tiến trình nảy nhịp (PuzzleProgressBar)

Thanh tiến trình nằm ngang ở đáy màn hình hiển thị tiến trình tiến tới lời giải đáp của bài hát:

* **Đồng bộ hoá mượt mà**: Tỉ lệ lấp đầy (`fill_ratio`) được nội suy tuyến tính liên tục theo thời gian thực từ 0.0 đến `reveal_time` (`fill_ratio = clampf(current_time / reveal_time, 0.0, 1.0)`).
* **Neon Glow & Sparks**:
  - Vẽ một đốm sáng neon rực rỡ dẫn đầu thanh progress.
  - Liên tục phát sinh các hạt lửa nhỏ (spark embers) bám theo đầu thanh progress, bay lùi về sau và nhạt dần theo thời gian thực.
* **Hiệu ứng nảy nhịp (Beat Pulse)**:
  - Mỗi khi bóng va chạm phát note (`note_triggered`), thanh tiến trình giật phồng nhẹ theo chiều dọc lên `1.15` lần (`pulse_scale = 1.15`).
  - Thanh tiến trình co lại mượt mà về kích thước gốc trong 0.15 giây sau đó nhờ nội suy bình phương (`lerpf(1.15, 1.0, t * t)`).

---

## 5. Quy tắc Vật lý cụ thể theo Mode

Hai chế độ Puzzle kế thừa trọn vẹn thuật toán vật lý satisfying của chế độ Bounce tương ứng:

### 5.1. Circle Puzzle (`circle_puzzle`)
* Sử dụng bộ thư viện toán học thuần túy `CircleBouncePhysics.gd`.
* Bóng nảy bên trong đấu trường hình tròn bán kính 470.0px, tâm (540, 1080).
* Áp dụng đầy đủ mô phỏng trọng lực giả lập trục Y (bay xuống nhanh hơn 17.5%, bay lên chậm hơn 15%), bóp góc phản xạ hướng tâm và bù nhịp nhạc hình học (`tempo_compensation_min = 0.75`).

### 5.2. Polygon Puzzle (`polygon_puzzle`)
* Sử dụng bộ thư viện toán học thuần túy `PolygonBouncePhysics.gd`.
* Đấu trường có dạng hình đa giác đều. Tại thời điểm khởi tạo (`setup`), hệ thống tự động chọn ngẫu nhiên số cạnh từ tập hợp `[4, 5, 6]` (tương ứng với các hình dạng Square, Pentagon, Hexagon) để tăng tính đa dạng cho mỗi lần chơi.
* Áp dụng thuật toán va chạm cạnh, phản xạ theo pháp tuyến cạnh, và đẩy lùi bóng hướng tâm để tránh kẹt bóng.

---

## 6. Sự kiện phát ra (Emitted Events)

Cả hai chế độ chơi đều kế thừa hệ thống phát tín hiệu chuẩn hóa thông qua `SimulationController`:

* **`ball_collided`**: Gửi kèm thông tin va chạm (`CollisionInfo` hoặc `PolygonCollisionInfo`) để TrailRenderer vẽ vệt nảy và ArenaView kích hoạt nháy sáng biên neon.
* **`note_triggered`**: Kích hoạt phát nốt nhạc qua `AudioNotePlayer`, nảy thanh progress bar, và lật mở mảnh ghép đĩa than.
