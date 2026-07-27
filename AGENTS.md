# AGENTS.md - Godot Project

## Current State

- Dự án Godot đã được thiết lập đầy đủ (`project.godot`, các scene `.tscn`, và các script `.gd`).
- Công cụ kiểm tra biên dịch/cú pháp hoạt động ổn định thông qua Godot CLI headless.

## Scope Boundary

- Godot là môi trường mô phỏng/render runtime: load và gộp 2 file cấu hình (Job Data & Gameplay Template), khởi tạo các scene objects, chạy chế độ chơi hiện hành, phát các note nhạc thông qua note_triggered, và thực hiện render đầu ra.
- Không thêm phần phân tích âm thanh, sinh note clip hay sinh `video_config.json` trực tiếp tại đây.
- Các tài liệu `shared/JSON_CONTRACT.md`, `shared/video_config.schema.json`, và `shared/VALIDATION_RULES.md` vẫn là nguồn chân lý cho hợp đồng cấu hình.

## Architecture To Preserve

- Tuân thủ mô hình Clean Architecture (`presentation -> application -> domain`).
- **Cấu hình 2 Thành phần (Job Data & Gameplay Template)**:
  - Dữ liệu bài hát nằm trong `video_config.json` ở job folder (chỉ chứa notes, duration, output_name, text overlays).
  - Quy tắc chơi nằm trong `shared/gameplay_template.json` (chứa game_mode, visual, ball/arena settings, phases).
  - `ConfigLoader.gd` nạp song song, thực hiện Deep Merge và tự động scale `phases[-1].end_time` khớp với `duration` bài hát.
- Giữ domain logic độc lập với các node engine (không kế thừa Node/SceneTree).
- Giữ `Main.gd` mỏng nhẹ, chỉ chịu trách nhiệm nạp cấu hình và kết nối tín hiệu.

## Planned Layout

- Scenes: `scenes/Main.tscn`, `scenes/AudioNotePlayer.tscn`, `scenes/UIOverlay.tscn`; mode scenes nằm dưới `scenes/modes/circle_bounce/`.
- Scripts: `scripts/domain/`, `scripts/application/`, `scripts/infrastructure/`, `scripts/presentation/` với code của mode cụ thể nằm ở thư mục modes tương ứng.

## Simulation Rules (circle_bounce)

- Vòng tròn va chạm: `distance(ball.position, arena.center) + ball.radius >= arena.radius`.
- **Trọng lực mô phỏng (Y-axis Gravity Simulation)**: Tốc độ bóng tự động nhân thêm hệ số trục Y tức thời trong `update_position` (bay xuống tăng tốc tối đa +17.5%, bay lên giảm tốc tối đa -15%). Đường bay luôn giữ thẳng tuyệt đối.
- **Bóp góc phản xạ hướng tâm (Decaying Angle of Incidence)**:
  - Va chạm đầu tiên bẻ góc lớn (`1.25 rad` ~71.6°) để tạo đa giác nhiều cạnh.
  - Các va chạm tiếp theo tự động bóp góc phản xạ hướng tâm theo hệ số `decay_rate = lerp(0.008, 0.08, current_time / duration)` để đa giác giảm dần cạnh và trở thành đường thẳng xuyên tâm ở cuối bài hát.
- **Bù nhịp nhạc hình học (Geometric Tempo Compensation)**: Nhân vận tốc thực tế sau va chạm với `cos(theta)` (clamped `0.45` đến `1.0`) để giữ khoảng cách nhịp nốt nhạc va chạm luôn đồng đều/dồn dập mượt mà, bù đắp cho quãng đường bay dài khi xuyên tâm.
- Cooldown va chạm: `20 ms` (COLLISION_COOLDOWN_MS = 20.0).

## Audio Rules

- Godot phát note tiếp theo ở mỗi sự kiện va chạm hoặc kích hoạt note; không phát toàn bộ bài hát từ đầu.
- `loop_notes = true` sẽ quay vòng lại nốt đầu; `loop_notes = false` sẽ dừng phát nhạc khi hết danh sách nốt.
- Bắt buộc xử lý đường dẫn âm thanh qua `PathResolver.gd` để phân giải tương đối theo job folder.

## Signals And Coupling

- Các tín hiệu được phát ra từ `SimulationController`: `mode_event`, `note_triggered`, `phase_changed`, `simulation_finished`, `simulation_error`.
- `AudioNotePlayer` và các renderers giao diện lắng nghe tín hiệu, không tự tính toán vật lý hay va chạm.

## Error Handling

- File cấu hình thếu/sai định dạng JSON, thiếu note clips là lỗi chí mạng. Show lỗi qua `ErrorOverlay` và dừng chạy.

## Verification Checklist

- Gộp cấu hình thành công, scale phase end_time chính xác theo bài hát.
- Bóng bay trong arena phản xạ bóp góc từ đa giác về đường thẳng, tăng tốc/kích thước mượt theo phase.
- Nhịp nhạc va chạm luôn giữ đều đặn nhờ tempo compensation.
- Trọng lực mô phỏng hoạt động tự nhiên trên trục Y.
- Trail mờ dần theo thời gian thực và biến đổi màu nóng sang lạnh từ đầu trail tới cuối trail.
- Vòng tròn arena flash sáng neon toàn bộ biên khi bóng chạm.

## Godot Code Verification

- Mỗi khi có chỉnh sửa code liên quan đến Godot (file `.gd`, `.tscn`, `.tres`, `project.godot`), bắt buộc phải chạy lệnh kiểm tra lỗi cú pháp/biên dịch bằng Godot CLI headless tùy theo môi trường/máy tính hiện tại:
  - **Máy 1**:
    `& "D:\HOANG HA\Tai lieu game godot\Godot_v4.5-stable_win64.exe\Godot_v4.5-stable_win64_console.exe" --headless --check-only --path "D:\HOANG HA\Tai lieu game godot\game-marble-race-music-v-1.0"`
  - **Máy 2**:
    `& "D:\Tai lieu kenh algodoo\Godot_v4.5-stable_win64.exe\Godot_v4.5-stable_win64_console.exe" --headless --check-only --path "D:\Tai lieu Game Territory Wars New\game-marble-race-music-v-1.0"`
  - **Lệnh tự động nhận diện môi trường (PowerShell)**:
    `if (Test-Path -LiteralPath "D:\Tai lieu kenh algodoo\Godot_v4.5-stable_win64.exe\Godot_v4.5-stable_win64_console.exe") { & "D:\Tai lieu kenh algodoo\Godot_v4.5-stable_win64.exe\Godot_v4.5-stable_win64_console.exe" --headless --check-only --path "D:\Tai lieu Game Territory Wars New\game-marble-race-music-v-1.0" } else { & "D:\HOANG HA\Tai lieu game godot\Godot_v4.5-stable_win64.exe\Godot_v4.5-stable_win64_console.exe" --headless --check-only --path "D:\HOANG HA\Tai lieu game godot\game-marble-race-music-v-1.0" }`
- Đối với các thay đổi chỉ nằm ở các file tài liệu thiết kế (`.md`, `.txt`), **không cần** chạy lệnh kiểm tra trên.
