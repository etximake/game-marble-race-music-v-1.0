# 04 - Video Config Generator

## Muc tieu

Tao `video_config.json` de Godot doc va render video.

## Input

- Audio duration.
- Folder note clips.
- Danh sach note file.
- Preset mac dinh cho `game_mode`, gameplay cua mode dau tien, visual, text, phases.

## Output

```text
generated/jobs/job_001/video_config.json
```

## Default video config

```text
width: 1080
height: 1920
fps: 60
duration: lay tu audio hoac nguoi dung nhap
```

## Default game mode

```text
game_mode: circle_bounce
```

## Default circle_bounce gameplay config

### ball

```text
start_position: [540.0, 515.0]
start_velocity: [0.0, 600.0]
start_radius: 24.0
max_radius: 320.0
max_radius_ratio: 0.8
growth_per_hit: 1.025
speed_growth_per_hit: 1.012
max_speed: 1600.0
```

### arena

```text
type: circle
center: [540, 960]
radius: 470.0
line_width: 10.0
```

## Default visual config

```text
background_color: #050505
ball_color: #00ffcc
use_glow: true
use_rainbow_trail: true
trail_mode: web
trail_persistence: 1.0
impact_effect: true
```

## Default phases

Timeline cua phases tuy thuoc vao thoi luong cua audio (`duration`):
- Neu `duration > 10.0` giay:
  - `intro`: `0.0` den `5.0` giay
  - `build_up`: `5.0` den `10.0` giay
  - `final_storm`: `10.0` den `duration` giay
- Neu `duration <= 10.0` giay:
  - `intro`: `0.0` den `duration * 0.3` giay
  - `build_up`: `duration * 0.3` den `duration * 0.6` giay
  - `final_storm`: `duration * 0.6` den `duration` giay

Cac he so multiplier tuong ung cua tung phase:
- `intro`: `speed_multiplier=1.0`, `growth_multiplier=1.0`, `trail_multiplier=1.0`
- `build_up`: `speed_multiplier=1.2`, `growth_multiplier=1.15`, `trail_multiplier=1.3`
- `final_storm`: `speed_multiplier=1.6`, `growth_multiplier=1.35`, `trail_multiplier=2.0`

## Validate

Sau khi tao JSON, Python phai validate theo:

```text
shared/video_config.schema.json
```

Neu validate loi, khong xuat job hoan chinh.
