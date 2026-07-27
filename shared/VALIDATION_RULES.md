# Validation Rules For video_config.json

## Muc tieu

`video_config.json` la contract giua Python va Godot. File nay can duoc validate o hai muc:

```text
Schema validation
  Kiem tra shape, type, required field, enum, min/max co ban.

Semantic validation
  Kiem tra logic nghiep vu ma JSON Schema draft-07 kho hoac khong nen xu ly.
```

Godot runtime duoc thiet ke cho nhieu game mode. Validation phai tach rule chung va rule rieng theo `game_mode`.

Python phai validate truoc khi xuat job hoan chinh.

Godot nen validate lai cac loi critical de tranh render sai.

## Schema validation

Schema validation su dung:

```text
shared/video_config.schema.json
```

Schema v1.0 hien validate cac mode:

```text
game_mode = circle_bounce | polygon_bounce
```

Schema hien tai nen dam bao common fields:

- Co day du field bat buoc.
- Field dung type.
- `game_mode` nam trong danh sach mode duoc ho tro.
- `video.width`, `video.height`, `video.fps` lon hon 0.
- `video.duration` lon hon 0.
- `audio.note_mode` chi ho tro `next_note_on_trigger` trong v1.0.
- `audio.audio_delay_ms >= 0`.
- `audio.notes` co it nhat 1 item.
- `visual.background_color` va `visual.ball_color` la hex color.
- `visual.trail_mode` chi ho tro `short`, `long`, `web` cho `circle_bounce`.
- `visual.trail_persistence` nam trong 0 den 1.
- `phases` co it nhat 1 item.

Schema hien tai nen dam bao `circle_bounce` va `polygon_bounce` gameplay fields:

- `gameplay.ball.start_radius`, `max_radius`, `max_speed` lon hon 0.
- `gameplay.ball.growth_per_hit >= 1`.
- `gameplay.ball.speed_growth_per_hit >= 1`.
- `gameplay.arena.type = circle` (circle_bounce) hoac `square | pentagon | hexagon` (polygon_bounce).
- `gameplay.arena.radius > 0`.
- `gameplay.arena.line_width >= 0`.
- `gameplay.arena.sides >= 3` va `<= 12` (polygon_bounce).

## Semantic validation

Semantic validation kiem tra cac rule lien quan nhieu field hoac lien quan file system.

## Common semantic rules

### Mode rules

```text
game_mode must have a registered mode validator and mode controller.
gameplay must be validated by the active mode validator.
```

Godot nen fail fast neu `game_mode` khong duoc ho tro.

### Video rules

```text
video.duration should be between 1 and 600 seconds for technical safety.
video.fps should usually be 24, 30, 50, or 60.
video.width and video.height should match target platform.
```

MVP target Shorts:

```text
width: 1080
height: 1920
fps: 60
duration: 30-60 seconds recommended
```

Khong nen hard fail neu duration khac 30-60, tru khi nguoi dung bat che do strict.

### Audio rules

```text
audio.notes must be sorted by playback order.
audio.notes[*].index should start at 0.
audio.notes[*].index should increase by 1.
audio.note_clips_dir must exist.
Each note file must exist inside note_clips_dir.
Each note file should be a wav file for MVP.
```

`note_mode = next_note_on_trigger` co nghia la active game mode emit note trigger. Khong mac dinh trigger phai la collision trong common rules.

Recommended note count:

```text
100-400 note clips per video
```

### Phase rules

```text
phases must be sorted by start_time.
first phase should start at 0.
each phase end_time must be greater than start_time.
next phase start_time should equal previous phase end_time.
last phase end_time should equal video.duration.
```

Common multipliers:

```text
speed_multiplier should be > 0.
growth_multiplier should be > 0.
trail_multiplier should be >= 0.
```

Moi game mode quyet dinh multiplier nao co y nghia voi mode do.

Recommended MVP phases:

```text
intro: 0-25% duration
build_up: 25-75% duration
final_storm: 75-100% duration
```

### Text rules

```text
If show_text = false, top_text and bottom_text may be empty.
If show_text = true, at least one of top_text or bottom_text should be non-empty.
Text length should fit video layout.
```

MVP co the warning neu text qua dai.

## circle_bounce semantic rules

Nhung rule nay chi ap dung khi:

```text
game_mode = circle_bounce
```

### Ball rules

```text
gameplay.ball.max_radius >= gameplay.ball.start_radius
gameplay.ball.start_radius < gameplay.arena.radius
gameplay.ball.max_radius < gameplay.arena.radius, recommended but not always required
gameplay.ball.start_velocity length > 0
gameplay.ball.growth_per_hit >= 1
gameplay.ball.speed_growth_per_hit >= 1
gameplay.ball.max_speed > initial speed
```

Neu `max_radius` gan bang hoac lon hon `arena.radius`, ball co the ket hoac che het man hinh. Nen fail hoac warning tuy strict mode.

### Arena rules (circle)

```text
gameplay.arena.type must be circle for circle_bounce v1.0.
gameplay.arena.radius > 0.
gameplay.arena.center should be inside video frame.
gameplay.arena.radius should fit inside video frame.
gameplay.arena.line_width >= 0.
```

Fit check:

```text
center.x - radius >= 0
center.x + radius <= video.width
center.y - radius >= 0
center.y + radius <= video.height
```

Co the cho phep arena vuot frame trong tuong lai, nhung MVP nen warning hoac fail.

## polygon_bounce semantic rules

Nhung rule nay chi ap dung khi:

```text
game_mode = polygon_bounce
```

### Ball rules

Giong `circle_bounce` (dung chung `BallState`):

```text
gameplay.ball.max_radius >= gameplay.ball.start_radius
gameplay.ball.start_radius < gameplay.arena.radius
gameplay.ball.start_velocity length > 0
gameplay.ball.growth_per_hit >= 1
gameplay.ball.speed_growth_per_hit >= 1
gameplay.ball.max_speed > initial speed
gameplay.ball.tempo_compensation_min should be >= 0.75 (recommended for polygon)
```

### Arena rules (polygon)

```text
gameplay.arena.type must be square | pentagon | hexagon.
gameplay.arena.radius > 0.
gameplay.arena.center should be inside video frame.
gameplay.arena.radius should fit inside video frame.
gameplay.arena.line_width >= 0.
gameplay.arena.sides must be an integer >= 3 and <= 12.
gameplay.arena.sides should match arena.type (4=square, 5=pentagon, 6=hexagon).
```

Polygon fit check (all vertices must be inside frame):

```text
for each vertex in vertices:
    vertex.x >= 0
    vertex.x <= video.width
    vertex.y >= 0
    vertex.y <= video.height
```

Co the cho phep da giac vuot frame trong tuong lai, nhung MVP nen warning hoac fail.

### Config errors for polygon_bounce

```text
arena.sides < 3 or > 12
arena.type not in [square, pentagon, hexagon]
arena.radius <= 0
```

### Visual rules for circle_bounce

```text
trail_persistence should match trail_mode.
```

Recommended:

```text
short: trail_persistence 0.1-0.35
long: trail_persistence 0.35-0.8
web: trail_persistence 0.8-1.0
```

Khong nen hard fail neu khac range, chi warning.

## Validation ownership

### Python ownership

Python phai validate day du truoc khi xuat job hoan chinh:

```text
schema validation
common semantic validation
mode-specific semantic validation
note file existence
metadata consistency
```

Neu fail critical:

```text
Do not mark job as complete.
Print clear error.
Return non-zero exit code.
```

### Godot ownership

Godot nen validate lai nhung loi critical luc load:

```text
config file exists
JSON parse success
required fields exist
game_mode supported
fps > 0
duration > 0
note files exist and can be loaded
gameplay required by active mode is valid
```

Godot khong can validate tat ca semantic rule neu Python da lam, nhung khong duoc crash khi config sai.

## Error severity

Nen chia loi thanh 3 muc:

### Error

Dung pipeline/render.

```text
missing required field
unsupported game_mode
invalid JSON
duration <= 0
fps <= 0
no notes
note file missing
invalid gameplay for active mode
phase end_time <= start_time
```

`circle_bounce` errors:

```text
ball radius invalid
arena radius invalid
arena type not circle
```

`polygon_bounce` errors:

```text
ball radius invalid
arena radius invalid
arena type not in [square, pentagon, hexagon]
arena.sides invalid (must be 3-12)
```

### Warning

Cho phep chay nhung can bao nguoi dung.

```text
duration outside 30-60 seconds
note count below 100 or above 400
arena slightly outside frame for circle_bounce
text too long
trail_persistence unusual for selected trail_mode
```

### Info

Thong tin debug.

```text
using default preset
converted mp3 to wav
generated fixed interval markers
loop_notes enabled
selected game_mode circle_bounce
```

## Validation result format

Python validator nen tra ve structure ro rang:

```json
{
  "valid": false,
  "errors": [
    {
      "path": "gameplay.ball.start_radius",
      "message": "start_radius must be greater than 0"
    }
  ],
  "warnings": [
    {
      "path": "audio.notes",
      "message": "note count is below recommended minimum 100"
    }
  ]
}
```

Godot co the dung format don gian hon de show overlay.

## Path resolution rules

Preferred MVP:

```text
Godot receives path to job folder.
note_clips_dir is resolved relative to job folder if relative.
```

Vi du:

```text
job folder:
  generated/jobs/job_001/

video_config.json:
  audio.note_clips_dir = "note_clips/"
  audio.notes[0].file = "note_0001.wav"

resolved path:
  generated/jobs/job_001/note_clips/note_0001.wav
```

## Definition of done

Validation system duoc xem la dat MVP khi:

- Python generated config pass schema validation.
- Python generated config pass common va `circle_bounce` semantic validation.
- Validator bao loi ro field path khi config sai.
- Godot khong crash voi config sai, ma show error overlay.
