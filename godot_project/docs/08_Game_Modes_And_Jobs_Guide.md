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
- **Runtime Timeline**: Tính phase từ `timeline` snapshot và `video.duration`, đồng thời tính quiz reveal theo `reveal_ratio`.

---

## 2. Quy trình Thêm một Game Mode mới

Dự án hỗ trợ 2 game mode: `circle_bounce` (arena tròn) và `polygon_bounce` (arena đa giác). Để thêm một game mode mới, bạn thực hiện theo 5 bước sau:

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
   const SUPPORTED_MODES = ["circle_bounce", "polygon_bounce"]
   ```
2. Mở `scripts/application/GameModeFactory.gd`, đăng ký Controller và View Scene tương ứng:
   ```gdscript
   static func create_controller(mode_name: String, gameplay_config: Dictionary) -> RefCounted:
       match mode_name:
           "circle_bounce":
               ...
           "polygon_bounce":
               var script = load("res://scripts/application/modes/polygon_bounce/PolygonBounceModeController.gd")
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
      - Các hệ số `"growth_multiplier"` và `"speed_multiplier"` của từng phase sẽ được động cơ **nội suy trơn mượt theo thời gian thực (smoothstep lerp)**. 
      - Mỗi khi va chạm xảy ra, hệ số tại thời điểm tương ứng sẽ nhân thêm vào phần tăng trưởng cơ bản của va chạm đó.
    - Điều chỉnh màu sắc, hiệu ứng glow, trail mode trong mục `"visual"`. Đồng thời hỗ trợ các cấu hình hiển thị **Ball Icon / Quiz Quiz** mới:
      - `"use_ball_icon"`: Bật/tắt chế độ hiển thị ảnh icon thay cho màu bóng đơn sắc.
      - `"ball_icon_path"`: Đường dẫn file ảnh tĩnh (`res://...`) hoặc tương đối trong job folder. Nếu trống/lỗi, game tự vẽ **Question Mark Placeholder** (`?`) dạng vector sắc nét trên nền tím.
      - `"icon_silhouette_mode"`: Khi bật `true`, quả bóng sẽ hiển thị bóng đen đơn sắc bí ẩn phục vụ cho thể loại video Quiz đoán nhân vật.
      - `"icon_reveal_phase"`: Giai đoạn hé lộ màu sắc thật của ảnh icon (mặc định `"final_storm"`).
      - `"icon_rotation_mode"`: Cách thức xoay ảnh: `"none"` (giữ thẳng đứng), `"velocity"` (xoay mặt theo hướng di chuyển của bóng), hoặc `"spin"` (tự động xoay tròn liên tục).
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
