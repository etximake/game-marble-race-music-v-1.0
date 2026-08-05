# 08 - Hướng dẫn Thay đổi Game Mode và Cấu hình Job mới trong Godot

Tài liệu này hướng dẫn cách kết nối của các Game Mode với Core Engine, kiến trúc 2 file Cấu hình (Job Song Data & Gameplay Template), và cách khởi chạy các Job (Music / Video Config) trong dự án Godot.

---

## 1. Kiến trúc Cấu hình 2 Thành phần (Dual Config Architecture)

Để tối ưu khả năng tái sử dụng và tránh trùng lặp mã cấu hình, hệ thống tách biệt cấu hình thành 2 file độc lập trước khi import vào `Main.gd`:

1. **Job Song Data (`video_config.json`)**: Nằm trong thư mục từng Job. Chứa dữ liệu bài hát (`audio.notes`, `video.duration`, `video.output_name`, `text` overlays, job assets).
2. **Gameplay Snapshot (`gameplay_config.json`)**: Nằm cạnh Job Song Data. Python tạo snapshot này từ `shared/gameplay_template.json` hoặc preset polygon. Chứa mode, gameplay, visual, quiz, timeline, resolution và phases.

```text
  [Job Song Data (video_config.json)]        [Gameplay Snapshot (gameplay_config.json)]
 (Duration, Audio Notes, Text)              (Game Mode, Ball/Arena, Visual, Phases)
                   │                                             │
                   └──────────────────────┬──────────────────────┘
                                          ▼
                                 [ConfigLoader.gd]
                               (Deep Merge & Runtime Timeline)
                                          │
                                          ▼
                                  [VideoConfig (Merged)]
                                          │
                                          ▼
 [Main.gd] ◄─── (Khởi tạo & Kết nối tín hiệu) ───► [SimulationController.gd]
      │                                                      │
      ├─► [GameModeRegistry] (Kiểm tra hỗ trợ)                 │ (Mỗi frame gọi update)
      ├─► [GameModeFactory]  (Tạo Controller & View)          │
      │          │                                           ▼
      │          ├─► Instantiates: [ActiveModeController] ◄──┘
      │          └─► Instantiates: [ActiveModeView] (Node2D)
      │                                   ▲
      ▼                                   │ (Gửi các GameEvent)
 [AudioNotePlayer] ◄── (Tín hiệu note_triggered) ───┘
```

Tại runtime, `ConfigLoader.gd` thực hiện:
- **Deep Merge**: Trộn Job Song Data với Gameplay Snapshot của chính job.
- **Runtime Timeline**: Tinh quiz reveal_time tu `video.duration` (`reveal_time = max(duration - 8.0, duration * 0.70)`). Loai bo phu thuoc vao `reveal_ratio` tu gameplay snapshot. Tu dong xay dung lai 4 phase co dinh (intro, build_up, final_storm, climax_storm).

---

## 2. Quy trình Thêm một Game Mode mới

Dự án hỗ trợ 4 game mode: `circle_bounce` (arena tròn), `polygon_bounce` (arena đa giác), `circle_puzzle` (arena tròn kết hợp đĩa nhạc đoán bài hát) và `polygon_puzzle` (arena đa giác kết hợp đĩa nhạc đoán bài hát). Để thêm một game mode mới, bạn thực hiện theo 5 bước sau:

### Bước 1: Khai báo cấu trúc dữ liệu (Domain State)
Tạo thư mục `scripts/domain/modes/<mode_name>/`. Tạo các file chứa trạng thái của mode đó:
- `<Mode>State.gd`: Chứa số lần va chạm, trạng thái của bóng, hình dạng hộp chứa.
- `<Mode>Physics.gd`: Chứa các hàm xử lý toán học thuần túy (tính toán va chạm, phản xạ vận tốc, cập nhật vị trí bóng). *Lưu ý: Script này không kế thừa Node và không dùng các API của Godot.*

### Bước 2: Tạo Controller điều phối (Application Controller)
Tạo thư mục `scripts/application/modes/<mode_name>/`.
- Tạo `<Mode>ModeController.gd` kế thừa `RefCounted`.
- Khai báo 2 phương thức bắt buộc:
  ```gdscript
  func setup(config: Dictionary) -> void:
      # Phân tích config từ cấu hình gameplay đã gộp và tạo trạng thái ban đầu

  func update(delta: float, current_time: float, phase: Dictionary) -> Array:
      # 1. Gọi <Mode>Physics để cập nhật vị trí bóng và tính toán va chạm.
      # 2. Nếu va chạm xảy ra, tăng hit_count, thay đổi kích thước/vận tốc theo Phase.
      # 3. Trả về mảng các `GameEvent` (ví dụ: ball_collided, note_triggered).
  ```
  - Hỗ trợ thêm `update_with_phases(delta, current_time, phases, phase)` để nội suy phase multiplier.

### Bước 3: Tạo giao diện hiển thị (Presentation View)
Tạo thư mục `scenes/modes/<mode_name>/` và `scripts/presentation/modes/<mode_name>/`.
- Tạo scene `<Mode>Mode.tscn` với script đính kèm là `<Mode>View.gd`.
- Script View phải có các phương thức:
  ```gdscript
  func setup(p_controller: RefCounted, p_visual_config: Dictionary, job_folder: String = "", phases: Array = []) -> void:
      # Liên kết với controller để vẽ nền, biên, bóng và trail ban đầu.

  func handle_mode_event(event: GameEvent) -> void:
      # Nhận các sự kiện từ Controller chuyển tới (ví dụ: "ball_collided" để tạo hiệu ứng flash, pulse).
  ```

### Bước 4: Đăng ký Mode mới vào Factory
Mặc dù hệ thống chỉ chạy duy nhất một chế độ chơi tại một thời điểm (được quyết định bởi trường `"game_mode"` trong `gameplay_config.json`), bạn vẫn cần đăng ký tất cả các chế độ chơi mà dự án hỗ trợ vào Factory để hệ thống có thể phân giải và tải động chính xác chế độ chơi được yêu cầu.

Các bước thực hiện đăng ký:
1. Mở `scripts/application/GameModeRegistry.gd`, thêm tên mode vào mảng hỗ trợ:
   ```gdscript
   const SUPPORTED_MODES = ["circle_bounce", "polygon_bounce", "circle_puzzle", "polygon_puzzle"]
   ```
2. Mở `scripts/application/GameModeFactory.gd`, đăng ký Controller và View Scene tương ứng:
   ```gdscript
   static func create_controller(mode_name: String, gameplay_config: Dictionary) -> RefCounted:
       match mode_name:
           "circle_bounce":
               ...
           "polygon_bounce":
               ...
           "circle_puzzle":
               var script = load("res://scripts/application/modes/circle_puzzle/CirclePuzzleModeController.gd")
               if script:
                   var controller = script.new()
                   controller.setup(gameplay_config)
                   return controller
           "polygon_puzzle":
               var script = load("res://scripts/application/modes/polygon_puzzle/PolygonPuzzleModeController.gd")
               if script:
                   var controller = script.new()
                   controller.setup(gameplay_config)
                   return controller
       return null

   static func get_mode_view_path(mode_name: String) -> String:
       match mode_name:
           "circle_bounce":
               return "res://scenes/modes/circle_bounce/CircleBounceMode.tscn"
           "polygon_bounce":
               return "res://scenes/modes/polygon_bounce/PolygonBounceMode.tscn"
           "circle_puzzle":
               return "res://scenes/modes/circle_puzzle/CirclePuzzleMode.tscn"
           "polygon_puzzle":
               return "res://scenes/modes/polygon_puzzle/PolygonPuzzleMode.tscn"
       return ""
   ```

---

## 3. Cách chỉ định chạy 1 Game Mode hoặc Thay đổi Quy tắc Gameplay

Game mode và các thông số vật lý (tốc độ bóng, bán kính tối đa, kiểu hiệu ứng visual, quiz và phases) được snapshot vào `generated/jobs/<job_id>/gameplay_config.json`. `shared/gameplay_template*.json` chỉ là preset đầu vào cho Python.

### Cách thay đổi Game Mode hoặc Thông số Hệ thống:

1. **Thay đổi Game Mode:**
    Chọn preset gameplay khi tạo job trong profile Python. Với `polygon_bounce`, đặt `gameplay_template_path` tới `shared/gameplay_template_polygon.json`.
   - Arena type: `"square"` (4 cạnh), `"pentagon"` (5 cạnh), `"hexagon"` (6 cạnh).

2. **Thay đổi Cấu hình Vật lý / Visual:**
    - Điều chỉnh vị trí, vận tốc, bán kính, tỷ lệ tăng trưởng trong mục `"gameplay.ball"`. Trong đó:
      - `"start_position"`: Mặc định được thiết lập sát biên trên đấu trường tại `[540.0, 515.0]` để bóng nảy rơi thẳng đứng xuống dưới.
      - `"start_velocity"`: Thiết lập thẳng đứng `[0.0, 600.0]`. Sau cú nảy đầu tiên ở đáy đấu trường, hệ thống bóp góc va chạm ban đầu (`hit_count <= 2`) sẽ tự động bẻ bóng lệch một góc lớn `~76` độ để vẽ hình đa giác nảy bắt mắt.
      - `"growth_per_hit"`: Tỷ lệ tăng bán kính cơ bản mỗi lần va chạm (ví dụ: `1.015` = tăng 1.5%).
      - `"speed_growth_per_hit"`: Tỷ lệ tăng tốc độ cơ bản mỗi lần va chạm (ví dụ: `1.012` = tăng 1.2%).
      - `"max_speed"`: Tốc độ tối đa giới hạn của bóng.
      - `"max_radius_ratio"`: Tỷ lệ bán kính bóng tối đa so với bán kính đấu trường (ví dụ: `0.55` = tối đa 55% đấu trường).
      - `"tempo_compensation_min"`: Hệ số bù nhịp tối thiểu (mặc định `0.45` cho circle_bounce, `0.75` cho polygon_bounce).
    - Với `polygon_bounce`, cấu hình `arena` có thêm trường `"sides"` xác định số cạnh đa giác (mặc định `4`):
      ```json
      "arena": {
        "type": "square",
        "center": [540, 960],
        "radius": 470,
        "line_width": 8,
        "sides": 4
      }
      ```
      - `sides = 4` → hình vuông (type: `"square"`)
      - `sides = 5` → hình ngũ giác (type: `"pentagon"`)
      - `sides = 6` → hình lục giác (type: `"hexagon"`)
     - Điều chỉnh tiến trình tiến hóa theo thời gian trong mục `"phases"`:
       - **Lưu ý**: ConfigLoader tu dong xay dung lai 4 phase co dinh tai runtime dua vao `video.duration` (intro 0-2s, build_up 2-10s, final_storm 10s-reveal_time, climax_storm reveal_time-end). Cac phase trong gameplay template bi override. Xem `scripts/infrastructure/ConfigLoader.gd` de biet chi tiet.
       - Cac he so `"growth_multiplier"` va `"speed_multiplier"` cua tung phase se duoc dong co **noi suy tuyen tinh lien tuc tren toan bo do dai phase** tu gia tri phase truoc do den gia tri phase hien tai.
    - Điều chỉnh màu sắc, hiệu ứng glow, trail mode trong mục `"visual"`. Đồng thời hỗ trợ các cấu hình hiển thị **Ball Icon / Quiz Quiz** mới:
      - `"use_ball_icon"`: Bật/tắt chế độ hiển thị ảnh icon thay cho màu bóng đơn sắc.
      - `"ball_icon_path"`: Đường dẫn file ảnh tĩnh (`res://...`) hoặc tương đối trong job folder. Nếu trống/lỗi, game tự vẽ **Question Mark Placeholder** (`?`) dạng vector sắc nét trên nền tím.
      - `"icon_silhouette_mode"`: Khi bật `true`, quả bóng sẽ hiển thị bóng đen đơn sắc bí ẩn phục vụ cho thể loại video Quiz đoán nhân vật.
      - `"icon_reveal_phase"`: Giai đoạn hé lộ màu sắc thật của ảnh icon (mặc định `"final_storm"`).
      - `"icon_rotation_mode"`: Cách thức xoay ảnh: `"none"` (giữ thẳng đứng), `"velocity"` (xoay mặt theo hướng di chuyển của bóng), hoặc `"spin"` (tự động xoay tròn liên tục).
      - `"show_progress_bar"`: Bật/tắt thanh tiến trình nhạc nhấp nháy theo nhịp ở đáy màn hình (Y=1680) cho các chế độ chơi. Mặc định `true` cho chế độ Puzzle, và `false` cho chế độ Bounce thông thường (có thể bật tùy chọn).
    - Tất cả các Job nhạc khi chạy sẽ tự động thừa hưởng cấu hình chung này.

---

## 4. Cách chạy hoặc thay đổi sang một Job mới

Job là một thư mục nằm trong `generated/jobs/` chứa cặp JSON (`video_config.json`, `gameplay_config.json`) và các file âm thanh (`note_clips/*.wav`).

Mặc định, nếu chạy trực tiếp từ Editor, Godot sẽ nạp cặp JSON từ `res://generated/jobs/job_001/`.

Để thay đổi sang một Job khác:

### Cách 1: Thay đổi bằng Command Line (Khuyên dùng khi render tự động hàng loạt)
Khởi chạy Godot console với file Job Music JSON. Gameplay snapshot được tự động tìm cạnh file này:
```powershell
& "Godot_v4.5-stable_win64_console.exe" --headless --path "D:\game-marble-race-music-v-1.0" -- --config "res://generated/jobs/job_002/video_config.json"
```
*Hệ thống trong `Main.gd` tự động suy ra Job folder từ `--config` và `ConfigLoader.gd` đọc `gameplay_config.json` cạnh file đó.*

### Cách 2: Thay đổi trực tiếp trong code Main.gd (Khi cần debug nhanh trên Editor)
Mở `scripts/presentation/Main.gd` và cập nhật trực tiếp biến mặc định ở các dòng 9-11:
```gdscript
var config_path: String = "res://generated/jobs/job_002/video_config.json"
var template_path: String = ""
var job_folder: String = ""
```

---

## 5. Chi tiết Cơ chế và Cách Tùy chỉnh các Pha Chuyển động của Quả bóng

Cơ chế mô phỏng chuyển động của quả bóng trong chế độ `circle_bounce` (và tương tự ở `polygon_bounce`) được xây dựng dựa trên sự phối hợp chặt chẽ giữa logic Vật lý thực tế và các tham số điều chỉnh trong file cấu hình `gameplay_config.json`.

### 5.1. Mô phỏng Trọng lực giả lập theo trục Y (Y-axis Gravity Simulation)
Không giống như trọng lực chuẩn rơi tự do khiến đường bay của bóng bị cong parabol, game sử dụng cơ chế **Gravity Simulation giữ quỹ đạo bay thẳng tuyệt đối** để đảm bảo nhịp điệu va chạm đều đặn:
* **Nguyên lý (`CircleBouncePhysics.gd`)**: Vận tốc bóng được nhân thêm hệ số trục Y tức thời:
  * **Khi bóng bay xuống (`dir.y > 0`)**: Vận tốc tăng tốc tối đa **+17.5%**.
  * **Khi bóng bay lên (`dir.y < 0`)**: Vận tốc giảm tốc tối đa **-15.0%**.
* **Mục tiêu**: Tạo cảm giác rơi tự nhiên (nặng hơn khi đi xuống, chậm lại khi đi lên) nhưng quỹ đạo bay vẫn là các đường thẳng tắp, thỏa mãn thị giác (satisfying).

### 5.2. Thuật toán Bóp góc phản xạ hướng tâm (Decaying Angle of Incidence)
Để tạo ra các hình vẽ hình học đẹp mắt (đa giác) ở đầu video và quy về đường thẳng xuyên tâm ở cuối video, góc nảy của bóng được bẻ lái tự động:
* **Giai đoạn đầu (Thời gian < 60% thời lượng)**:
  * Hệ thống chia góc nảy để bóng vẽ các đa giác đều $N$ cạnh ở trung tâm.
  * Số cạnh $N$ giảm dần theo thời gian:
    * `0% - 12%`: Đa giác **10 cạnh** (Góc nảy $\approx 72^\circ$).
    * `12% - 24%`: Đa giác **8 cạnh** (Góc nảy $\approx 67.5^\circ$).
    * `24% - 36%`: Đa giác **6 cạnh** (Góc nảy $\approx 60^\circ$).
    * `36% - 48%`: Đa giác **5 cạnh** (Góc nảy $\approx 54^\circ$).
    * `48% - 60%`: Đa giác **4 cạnh** (Góc nảy $\approx 45^\circ$).
* **Giai đoạn giữa (60% - 72% thời lượng)**:
  * Góc nảy ép sát tâm đấu trường (chỉ lệch $1.5^\circ$) tạo ra các đường thẳng xoay nhẹ.
* **Giai đoạn cuối (72% - 100% thời lượng)**:
  * Góc nảy mở rộng nhẹ ($14.0^\circ$) để vẽ các hình bông hoa mandala đối xứng trước khi bài hát kết thúc.

### 5.3. Bù nhịp nhạc hình học (Geometric Tempo Compensation)
Khi bóng nảy xuyên qua tâm đấu trường, quãng đường bay sẽ dài gấp đôi so với khi nảy sát rìa. Để tránh việc các nốt nhạc bị phát chậm lại (sai nhịp/lỗi tempo), hệ thống sử dụng cơ chế bù vận tốc:
* **Công thức**: Vận tốc thực tế sau va chạm được nhân với hệ số $\cos(\theta)$ (với $\theta$ là góc giữa vector nảy và vector hướng tâm).
* **Giới hạn bù (`tempo_compensation_min`)**: Giới hạn từ `0.45` đến `1.0`. Khi bóng bay xuyên tâm ($\cos(\theta) \approx 1$), vận tốc được giữ nguyên mức tối đa. Khi bóng nảy sát rìa ($\cos(\theta)$ nhỏ), vận tốc sẽ tự động giảm đi (tối đa giảm còn 45%) để giữ khoảng cách thời gian giữa các nốt luôn đều đặn.

### 5.4. Hướng dẫn Tùy chỉnh Các Pha (Phases Configuration)
Hệ thống chia tiến trình chơi thành 4 giai đoạn (Phase) duoc ConfigLoader tu dong xay dung tai runtime:

| Phase | Thoi gian | speed_multiplier | growth_multiplier | trail_multiplier | trajectory_control |
|---|---|---|---|---|---|
| `intro` | 0s → 2s (hoac 20% neu <12s) | 1.0 | 1.0 | 1.5 | 0.0 |
| `build_up` | 2s → 10s (hoac 20%-50%) | 2.0 | 2.0 | 2.0 | 0.5 |
| `final_storm` | 10s → reveal_time | 3.5 | 4.0 | 3.0 | 1.0 |
| `climax_storm` | reveal_time → end | 10.0 | 10.0 | 3.5 | 1.0 |

Voi `reveal_time = max(duration - 8.0, duration * 0.70)`, dam bao luon co it nhat 8 giay (hoac 30% duration) cho pha climax_storm.

```json
  "phases": [
    {
      "name": "intro",
      "speed_multiplier": 1.0,
      "growth_multiplier": 1.0,
      "trail_multiplier": 1.5,
      "trajectory_control": 0.0
    },
    {
      "name": "build_up",
      "speed_multiplier": 2.0,
      "growth_multiplier": 2.0,
      "trail_multiplier": 2.0,
      "trajectory_control": 0.5
    },
    {
      "name": "final_storm",
      "speed_multiplier": 3.5,
      "growth_multiplier": 4.0,
      "trail_multiplier": 3.0,
      "trajectory_control": 1.0
    },
    {
      "name": "climax_storm",
      "speed_multiplier": 10.0,
      "growth_multiplier": 10.0,
      "trail_multiplier": 3.5,
      "trajectory_control": 1.0
    }
  ]
```

#### Cơ chế nội suy chuyển pha mượt mà (Continuous Linear Interpolation)
Động cơ game khong tang dot ngot toc do hay kich thuoc cua bong khi doi pha. Thay vao do:
* **Ham `PhaseRules.gd`**: Su dung **noi suy tuyen tinh lien tuc tren TOAN BO do dai cua phase** hien tai, tu gia tri cua phase truoc do den target cua phase hien tai: `value = lerp(prev_phase_value, current_phase_value, (time - phase_start) / phase_duration)`.
* **Vi du**: Trong suot 8 giay cua `build_up`, `speed_multiplier` duoc noi suy muot ma tu `1.0` (cuoi intro) len `2.0` (cuoi build_up), dam bao khong co hien tuong dung yen (plateau) giua phase. Cach nay tao cam giac tang toc muot ma va thoa man cho nguoi xem xuyen suot toan bo bai hat.
* **Pha climax_storm**: Bong thoat khoi arena, bay tu do toan man hinh (va cham 4 canh viewport 1080x1920), troi goc ngau nhien ±10 do/giay, ban kinh phat trien dong `climax_start_radius + time_in_climax * 45` (toi da 300px), toc do toi da `max_speed * 1.5`.
