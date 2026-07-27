# JSON Contract - video_config.json

## Muc dich

`video_config.json` la hop dong du lieu giua Python project va Godot project.

- Python phai tao JSON dung format nay.
- Godot chi doc va su dung JSON nay, khong phan tich nhac.
- Godot runtime duoc thiet ke de ho tro nhieu game mode; `circle_bounce` la mode dau tien.

## Nguyen tac chung

- Don vi thoi gian: giay.
- Don vi vi tri/kich thuoc: pixel.
- Mau sac: hex string, vi du `#00ffcc`.
- Duong dan file nen tuong doi theo job folder de Godot resolve on dinh.
- `notes` phai duoc sap xep theo thu tu phat.
- Neu het note va `loop_notes = true`, Godot quay lai note dau tien.
- Neu het note va `loop_notes = false`, Godot khong phat note moi.
- Cac field chung nam o top-level; rule rieng cua mode nam trong `gameplay`.

## Field bat buoc

Job Music JSON:

```text
video
audio
text
job_assets
```

Merged runtime config additionally contains:

```text
game_mode
gameplay
visual
phases
quiz
timeline
```

## game_mode

```json
"circle_bounce"
```

`game_mode` cho Godot biet phai tao mode controller/view nao.

Cac mode hien tai duoc ho tro:
- `"circle_bounce"`: arena tron
- `"polygon_bounce"`: arena da giac (vuong, ngu giac, luc giac)

MVP v1.0 chi validate `circle_bounce`, nhung kien truc Godot khong duoc hard-code moi runtime theo ball/circle.

## video

```json
{
  "width": 1080,
  "height": 1920,
  "fps": 60,
  "duration": 46,
  "output_name": "music_ball_001"
}
```

Y nghia:

- `width`, `height`: kich thuoc video.
- `fps`: frame rate render.
- `duration`: thoi luong simulation.
- `output_name`: ten file render du kien.

## audio

```json
{
  "note_mode": "next_note_on_trigger",
  "note_clips_dir": "note_clips/",
  "audio_delay_ms": 0,
  "loop_notes": true,
  "notes": [
    {"index": 0, "file": "note_0001.wav"}
  ]
}
```

Y nghia:

- `note_mode`: MVP dung `next_note_on_trigger`; active game mode emit note trigger.
- `note_clips_dir`: folder chua note clip, nen relative theo job folder.
- `audio_delay_ms`: delay neu can chinh sync.
- `loop_notes`: lap lai note khi het danh sach.
- `notes`: danh sach note clip theo thu tu.

Voi `circle_bounce`, note trigger mac dinh la wall collision hop le.
Voi `polygon_bounce`, note trigger mac dinh la edge collision cua da giac.

## gameplay

`gameplay` chua config rieng theo `game_mode`.

### circle_bounce gameplay

```json
{
  "ball": {
    "start_position": [540, 960],
    "start_velocity": [420, -520],
    "start_radius": 24,
    "max_radius": 520,
    "growth_per_hit": 1.025,
    "speed_growth_per_hit": 1.012,
    "max_speed": 2600
  },
  "arena": {
    "type": "circle",
    "center": [540, 960],
    "radius": 470,
    "line_width": 10
  }
}
```

Y nghia:

- `ball`: state/rule rieng cua `circle_bounce`.
- `arena`: boundary rieng cua `circle_bounce`; MVP support arena circle va polygon trong mode tuong ung.

Mode khac sau nay co the co schema `gameplay` khac, khong can fake `ball`/`arena`.

### polygon_bounce gameplay

```json
{
  "ball": {
    "start_position": [540, 515],
    "start_velocity": [0, 600],
    "start_radius": 24,
    "max_radius": 320,
    "max_radius_ratio": 0.55,
    "growth_per_hit": 1.020,
    "speed_growth_per_hit": 1.015,
    "max_speed": 1600,
    "tempo_compensation_min": 0.75
  },
  "arena": {
    "type": "square",
    "center": [540, 960],
    "radius": 470,
    "line_width": 8,
    "sides": 4
  }
}
```

Y nghia:

- `ball`: Giong `circle_bounce`. Dung chung `BallState`.
- `arena`: Boundary da giac. `sides` xac dinh so canh (4=vuong, 5=ngu giac, 6=luc giac). `type` la label hien thi (`"square"`, `"pentagon"`, `"hexagon"`).

## visual

```json
{
  "background_color": "#050505",
  "ball_color": "#00ffcc",
  "use_glow": true,
  "use_rainbow_trail": true,
  "trail_mode": "web",
  "trail_persistence": 1.0,
  "impact_effect": true
}
```

`visual` la visual setting chung va co the duoc active mode dien giai theo cach rieng.

Voi `circle_bounce`, `trail_mode` nen ho tro:

- `short`
- `long`
- `web`

## text

```json
{
  "show_text": true,
  "top_text": "With every bounce, the ball evolves",
  "bottom_text": "Did you recognize the music?"
}
```

## phases

```json
[
  {
    "name": "intro",
    "start_time": 0,
    "end_time": 12,
    "speed_multiplier": 1.0,
    "growth_multiplier": 1.0,
    "trail_multiplier": 1.0
  }
]
```

Khuyen nghi 3 phase:

1. `intro`: cham, de hieu luat choi.
2. `build_up`: tang toc va tang visual.
3. `final_storm`: day toc do, size, trail de tao cao trao.

Phase multiplier la common input; moi game mode quyet dinh multiplier nao co y nghia voi mode do.

## Xu ly loi

Godot nen dung simulation va hien thi loi neu:

- Thieu field bat buoc.
- `game_mode` khong duoc ho tro.
- Khong tim thay note clip.
- `fps <= 0`.
- `duration <= 0`.
- Config gameplay cua active mode khong hop le.

Python nen validate schema va semantic rules truoc khi xuat JSON.
