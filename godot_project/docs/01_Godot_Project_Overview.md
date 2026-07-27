# 01 - Godot Project Overview

## Muc tieu

Godot tao video music game/simulation tu du lieu ma Python da chuan bi.

Godot runtime duoc thiet ke de ho tro nhieu game mode. Cac mode hien tai:

```text
circle_bounce
polygon_bounce
```

## Data flow

```text
video_config.json
  -> ConfigLoader
  -> VideoConfig
  -> GameModeFactory
  -> MainScene
  -> SimulationController
  -> Active GameModeController
  -> AudioNotePlayer
  -> Mode Visual Renderer
  -> UIOverlay
```

## Node/component chinh

### Main

Quan ly lifecycle chung:

- load config
- setup shared scene
- chon active game mode
- ket noi signals/events
- update timer
- dung khi het duration

### GameModeFactory

Chon game mode theo:

```text
video_config.game_mode
```

MVP modes:

```text
circle_bounce
polygon_bounce
```

### SimulationController

Dieu phoi runtime chung:

- update current time
- forward delta/time/phase vao active mode
- route mode events
- emit `note_triggered` cho audio
- dung simulation khi het duration

SimulationController khong duoc hard-code ball/circle.

### circle_bounce mode

Quan ly rule rieng cua bouncing ball mode trong arena tron:

- ball state
- arena state (circle)
- circle collision
- growth/speed evolution
- note trigger khi valid collision

### polygon_bounce mode

Quan ly rule rieng cua bouncing ball mode trong arena da giac (vuong, ngu giac, luc giac):

- ball state (dung chung BallState)
- arena state (polygon voi sides)
- polygon collision (line-segment-to-circle)
- growth/speed evolution
- note trigger khi valid collision

### AudioNotePlayer

Load note clips va phat note theo `note_triggered` event.

### Mode Visual Renderer

Moi mode co renderer rieng. Trong MVP:

`circle_bounce` co:
- BallView
- ArenaView (circle)
- TrailRenderer
- impact effect

`polygon_bounce` co:
- BallView (dung chung voi circle_bounce)
- PolygonArenaView (polygon)
- TrailRenderer (dung chung voi circle_bounce)
- impact effect

### UIOverlay

Hien top text va bottom text.

## Nguyen tac

Godot phai duoc dieu khien bang config, khong hard-code qua nhieu gia tri trong scene.

Runtime chung khong duoc hard-code ball/circle. Cac rule do thuoc `circle_bounce` mode hoac `polygon_bounce` mode.
