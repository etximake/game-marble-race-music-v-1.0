# 07 - Clean Architecture For Godot Project

## Muc tieu

Tai lieu nay dinh nghia cach to chuc Godot project de simulation va render video theo `video_config.json` mot cach ro rang, de test va de mo rong nhieu game mode.

Godot project co vai tro:

- Doc `video_config.json`.
- Chon active game mode theo `game_mode`.
- Tao scene/controller/view theo mode.
- Chay simulation lifecycle.
- Phat note clip khi active mode emit note trigger.
- Ve visual, impact effect, text overlay.
- Render video raw/output.

Godot project khong duoc:

- Phan tich nhac.
- Cat note clips.
- Sinh `video_config.json`.
- Phu thuoc vao chi tiet implementation cua Python.

## Nguyen tac kien truc

Godot dua tren Scene va Node, nhung van nen tach logic thanh cac layer:

```text
presentation -> application -> domain
infrastructure -> application/domain thong qua loader/service
```

Quy tac quan trong:

- Runtime chung khong duoc hard-code ball/circle/collision rules.
- Domain chung khong phu thuoc Node, SceneTree, AudioStreamPlayer.
- Mode-specific domain moi duoc chua physics/rule rieng cua mode.
- Audio player khong tu tinh collision; no chi phan ung voi note trigger.
- Trail/visual renderer khong tu doc JSON.
- Main scene chi dieu phoi, khong gom het logic vao mot script lon.

## Game mode model

Godot runtime ho tro nhieu mode bang cach chon mode theo:

```text
video_config.game_mode
```

Cac mode hien tai:

```text
circle_bounce
polygon_bounce
```

`circle_bounce` dung ball, circle arena, wall collision, web trail.
`polygon_bounce` dung ball, polygon arena (da giac), edge collision, web trail.
Nhung cac chi tiet nay khong phai rule chung cua toan runtime.

## Cau truc thu muc de xuat

```text
godot_project/
  project.godot
  README.md
  docs/

  scenes/
    Main.tscn
    UIOverlay.tscn
    AudioNotePlayer.tscn
    ErrorOverlay.tscn
    modes/
      circle_bounce/
        CircleBounceMode.tscn
        Ball.tscn
        Arena.tscn
        TrailRenderer.tscn
      polygon_bounce/
        PolygonBounceMode.tscn
        Ball.tscn
        Arena.tscn
        TrailRenderer.tscn

  scripts/
    domain/
      GameEvent.gd
      NoteTrigger.gd
      PhaseRules.gd
      NoteSequence.gd
      VideoConfig.gd
      modes/
        circle_bounce/
          CircleBounceState.gd
          BallState.gd
          ArenaState.gd
          CircleBouncePhysics.gd
          CollisionInfo.gd
        polygon_bounce/
          PolygonBounceState.gd
          PolygonBouncePhysics.gd
          PolygonCollisionInfo.gd
          PolygonArenaState.gd

    application/
      SimulationController.gd
      GameModeRegistry.gd
      GameModeFactory.gd
      GameModeRunner.gd
      RenderSession.gd

    infrastructure/
      ConfigLoader.gd
      PathResolver.gd
      NoteClipLoader.gd

    presentation/
      Main.gd
      UIOverlay.gd
      AudioNotePlayer.gd
      ErrorOverlay.gd
      modes/
        circle_bounce/
          CircleBounceView.gd
          BallView.gd
          ArenaView.gd
          TrailRenderer.gd
        polygon_bounce/
          PolygonBounceView.gd
          PolygonArenaView.gd
```

Neu MVP can nhe hon, co the gom it file hon, nhung van phai giu rule: runtime chung khong lan rule ball/circle vao audio, render, config loading.

## Domain layer

Domain layer chua rule cot loi, chia thanh common domain va mode-specific domain.

### Common domain

```text
GameEvent
  type
  time
  payload

NoteTrigger
  time
  source_event_type
  payload

PhaseRules
  get_current_phase(time, phases)
  get_speed_multiplier(time, phases)
  get_growth_multiplier(time, phases)
  get_trail_multiplier(time, phases)
  get_interpolated_value(time, phases, key, default_val)

NoteSequence
  get_next_note()
  reset()
  has_next_note()
```

`NoteSequence` khong phat audio. No chi quyet dinh note tiep theo la note nao.

### Mode-specific domain: circle_bounce

```text
CircleBounceState
  ball
  arena
  hit_count

BallState (dung chung giua circle_bounce va polygon_bounce)
  position
  velocity
  radius

ArenaState (circle)
  type
  center
  radius
  line_width

CircleBouncePhysics
  update_position(ball, delta)
  check_circle_collision(ball, arena)
  reflect_velocity(velocity, normal)
  resolve_inside_arena(ball, arena, normal)
  apply_evolution(ball, gameplay_config, growth_multiplier, speed_multiplier)
```

### Mode-specific domain: polygon_bounce

```text
PolygonBounceState
  ball     # BallState (dung chung)
  arena    # PolygonArenaState
  hit_count

PolygonArenaState
  type
  center
  radius      # ban kinh duong tron ngoai tiep
  line_width
  sides       # so canh (4=vuong, 5=ngu giac, 6=luc giac)
  vertices    # Array[Vector2] cac dinh da giac, computed tu center, radius, sides

PolygonBouncePhysics
  update_position(ball, delta)                   # dung chung logic trong luc giong circle
  closest_point_on_segment(p, a, b)             # tim diem gan nhat tren canh
  check_polygon_collision(ball, arena)           # line-segment-to-circle collision
  reflect_velocity(velocity, normal, ...)       # reflect giong circle, normal = edge normal
  resolve_inside_arena(ball, normal, penetration) # push ball doc theo edge normal
  apply_evolution(...)                           # dung chung logic tien hoa
```

`PolygonBouncePhysics` va `CircleBouncePhysics` khong duoc:

- Load config file.
- Play note.
- Spawn trail.
- Truy cap node tree.

## VideoConfig

`VideoConfig` la wrapper quanh JSON da parse.

Nen co accessor ro nghia:

```text
get_game_mode()
get_video_settings()
get_audio_settings()
get_gameplay_settings()
get_visual_settings()
get_text_settings()
get_current_phase(time)
```

Tranh viec nhieu script truy cap raw dictionary:

```text
config["gameplay"]["ball"]["start_radius"]
```

Chi `ConfigLoader` va `VideoConfig` nen biet raw JSON structure.

## Application layer

Application layer dieu phoi lifecycle simulation va active mode.

### SimulationController

Trach nhiem chung:

```text
load config
select game mode
setup active mode runner
update simulation time
forward delta/time to active mode
route mode events to audio/visual/ui
stop when duration reached
```

Flow moi frame:

```text
current_time += delta
phase = PhaseRules.get_current_phase(current_time)
events = active_mode.update(delta, current_time, phase)

for event in events:
  route_event(event)

if current_time >= video.duration:
  emit simulation_finished()
```

SimulationController khong nen tu goi `CircleBouncePhysics` truc tiep; viec do thuoc active mode.

### GameModeRegistry

Trach nhiem:

```text
register supported mode ids
map game_mode id -> mode factory/view/controller
reject unsupported game_mode
```

MVP registry:

```text
circle_bounce -> CircleBounceModeController / CircleBounceView
polygon_bounce -> PolygonBounceModeController / PolygonBounceView
```

### GameModeFactory

Trach nhiem:

- Tao mode controller theo `game_mode`.
- Truyen `gameplay`, shared settings, va resources can thiet.
- Khong parse raw JSON truc tiep neu `VideoConfig` da lam.

### GameModeRunner

Trach nhiem:

- Goi lifecycle cua active mode.
- Nhan `GameEvent` tu mode.
- Co the ap dung cooldown/event filtering neu la rule common.

### CircleBounceModeController

Mode dau tien nen co controller rieng:

```text
setup(circle_bounce_gameplay, shared_config)
update(delta, current_time, phase) -> list[GameEvent]
update_with_phases(delta, current_time, phases, phase) -> list[GameEvent]
teardown()
```

Controller nay moi duoc:

- Update ball state.
- Check circle collision.
- Apply growth/speed cap.
- Emit `ball_collided` va `note_triggered` events.

### PolygonBounceModeController

Mode thu hai co controller rieng:

```text
setup(polygon_bounce_gameplay, shared_config)
update(delta, current_time, phase) -> list[GameEvent]
update_with_phases(delta, current_time, phases, phase) -> list[GameEvent]
teardown()
```

Controller nay moi duoc:

- Update ball state (dung chung BallState).
- Check polygon collision (line-segment-to-circle).
- Parse `sides` tu config de tinh vertices da giac.
- Apply growth/speed cap.
- Emit `ball_collided` va `note_triggered` events.

### RenderSession

Trach nhiem:

- Ap dung width, height, fps tu config neu co the.
- Theo doi duration.
- Ket thuc render/session khi simulation finished.

Trong MVP, render co the chay tu Godot editor/movie maker. Chua can command line.

## Infrastructure layer

### ConfigLoader

Trach nhiem:

- Doc file `video_config.json`.
- Parse JSON.
- Kiem tra field bat buoc co ban.
- Tao `VideoConfig`.

ConfigLoader khong nen setup scene va khong chon mode truc tiep. Mode selection thuoc application layer.

### PathResolver

Trach nhiem:

- Resolve `note_clips_dir` va `note.file`.
- Ho tro path relative theo job folder.
- Tra ve full path Godot co the load.

Quy tac path can nhat quan voi `shared/JSON_CONTRACT.md`.

### NoteClipLoader

Trach nhiem:

- Load audio stream tu file note clip.
- Bao loi ro neu file thieu hoac load fail.
- Khong quyet dinh note nao duoc play tiep theo. Viec do cua `NoteSequence`.

## Presentation layer

Presentation layer gom scene/node that su.

### Main.gd

Trach nhiem:

- Khoi tao controller.
- Ket noi signal.
- Dieu phoi shared views va active mode view.

Khong nen chua toan bo physics/audio/visual logic.

### Mode views

Moi mode co view rieng.

`circle_bounce` view gom:

```text
CircleBounceView
BallView
ArenaView (circle)
TrailRenderer
```

`polygon_bounce` view gom:

```text
PolygonBounceView
BallView (dung chung)
PolygonArenaView (polygon)
TrailRenderer (dung chung)
```

`BallView` khong co logic circle/polygon, chi hien thi state cua ball; khong tu tinh collision.
`PolygonArenaView` ve da giac qua `draw_polyline`; `ArenaView` ve vong tron qua `draw_arc`.

### AudioNotePlayer.gd

Trach nhiem:

- Nhan `note_triggered` event.
- Lay next note tu `NoteSequence` hoac duoc controller truyen note.
- Play audio stream.
- Ton trong `audio_delay_ms` va `min_note_interval_ms`.

Khong doc JSON truc tiep neu co the tranh. Nen nhan settings da parse.

### UIOverlay.gd

Trach nhiem:

- Hien top text va bottom text.
- An/hi hien theo `text.show_text`.

### ErrorOverlay.gd

Trach nhiem:

- Hien loi config/audio/runtime.
- Dung simulation khi loi critical.

## Event and signal design

Nen dung event/signal de giam coupling.

Common signals:

```text
SimulationController
  signal mode_event(event)
  signal note_triggered(note_trigger)
  signal phase_changed(phase)
  signal simulation_finished()
  signal simulation_error(error)
```

Mode-specific event type for `circle_bounce`:

```text
ball_collided
ball_state_changed
```

Subscribers:

```text
AudioNotePlayer listens to note_triggered
CircleBounceView listens to mode_event
TrailRenderer listens to ball_collided mode_event
UIOverlay may listen to phase_changed
RenderSession listens to simulation_finished
ErrorOverlay listens to simulation_error
```

Quy tac:

- Mode-specific physics khong emit Godot signal truc tiep.
- Controller hoac Main la noi bridge domain event sang Godot signal.
- Component khong nen truy cap nhau truc tiep neu signal/event du dap ung.

## GameEvent payloads

Common shape:

```text
GameEvent
  type
  time
  payload
```

`circle_bounce` collision payload:

```text
CollisionInfo
  position
  normal
  hit_count
  time
  phase_name
  ball_radius
  ball_speed
```

Audio chi can `note_triggered`; trail cua `circle_bounce` can `ball_collided` payload.

## Error handling

Godot nen phan loai loi:

```text
ConfigFileNotFound
InvalidConfigJson
UnsupportedProjectVersion
UnsupportedGameMode
MissingRequiredConfigField
InvalidConfigValue
InvalidModeGameplay
NoteClipNotFound
AudioLoadFailed
SimulationRuntimeError
```

Quy tac MVP:

- Thieu config: show error va dung simulation.
- JSON sai: show error va dung simulation.
- `game_mode` khong support: show error va dung simulation.
- Thieu field bat buoc: show error va dung simulation.
- Thieu note clip: uu tien show error va dung simulation de tranh video sai audio.
- Audio delay/sync warning khong critical thi co the show warning.

## Clean code rules

### Khong tao God script qua lon

`Main.gd` khong nen lam tat ca:

```text
load config
select mode
simulate physics
play audio
draw trail
draw UI
render stop
```

Nen tach theo shared controller, mode controller, component va service.

### Ten file theo trach nhiem

Nen dung:

```text
GameModeRegistry.gd
GameModeFactory.gd
SimulationController.gd
CircleBouncePhysics.gd
NoteSequence.gd
ConfigLoader.gd
```

Tranh ten mo ho:

```text
GameManager.gd
System.gd
Helper.gd
Utils.gd
```

### Config access tap trung

Chi `ConfigLoader` va `VideoConfig` nen biet raw JSON structure.

Nhung script khac nen nhan settings/object da parse.

### Magic numbers

Nhung gia tri nhu collision cooldown, min note interval, small margin nen la const co ten trong component/mode so huu rule do:

```text
COLLISION_COOLDOWN_MS = 20
MIN_NOTE_INTERVAL_MS = 30
BOUNDARY_MARGIN = 0.5
```

### Deterministic simulation

Render offline can on dinh. Nen uu tien fixed delta theo fps neu Movie Maker/render pipeline yeu cau.

## Test va manual checklist

Godot MVP co the bat dau bang manual checklist neu chua setup automated test.

Common checklist:

```text
Valid config loads successfully
Unsupported game_mode shows error overlay
Missing config shows error overlay
Invalid JSON shows error overlay
Active mode is selected from config.game_mode
Note trigger plays next note
Loop notes works when loop_notes = true
No new notes when loop_notes = false and notes exhausted
Simulation stops at video.duration
```

`circle_bounce` checklist:

```text
Ball starts at configured position
Ball reflects inside circular arena
Hit count increments once per valid collision
Ball radius grows up to max_radius
Speed grows up to max_speed
Trail mode short/long/web changes persistence
```

`polygon_bounce` checklist:

```text
Ball starts at configured position
Ball reflects inside polygon arena (square/pentagon/hexagon)
Polygon sides configured via arena.sides (4/5/6)
Edge normal used for reflection instead of radial normal
Hit count increments once per valid collision
Ball radius grows up to max_radius
Speed grows up to max_speed
Trail mode short/long/web changes persistence
```

Neu co automated test sau nay, uu tien test domain rule:

```text
GameModeRegistry rejects unsupported mode
NoteSequence loop behavior
PhaseRules current phase lookup
CircleBouncePhysics reflection
CircleBounce collision detection
```

## MVP implementation order

Nen implement theo thu tu:

1. `project.godot` va scene Main toi thieu.
2. `ConfigLoader` doc example config.
3. `VideoConfig` wrapper voi `get_game_mode()` va `get_gameplay_settings()`.
4. `GameModeRegistry` va `GameModeFactory` voi mode `circle_bounce` duy nhat.
5. `SimulationController` mode-agnostic.
6. `CircleBounceState`, `BallState`, `ArenaState`, `CircleBouncePhysics`.
7. `CircleBounceModeController` chay ball trong circle va emit events.
8. `CircleBounceView`, `BallView`, `ArenaView` hien thi.
9. `NoteSequence`, `PathResolver`, `NoteClipLoader`.
10. `AudioNotePlayer` play note on `note_triggered`.
11. `TrailRenderer` cua `circle_bounce` voi mode `web` truoc.
12. `UIOverlay`.
13. Render stop theo duration.

## Definition of done

Godot MVP duoc xem la xong khi:

- Load duoc `video_config.json` tu job folder.
- Chon duoc active mode tu `game_mode`.
- Unsupported mode show error overlay.
- `circle_bounce` tao arena, ball, text theo config.
- `circle_bounce` va cham va reflect dung trong circle.
- Moi valid note trigger phat dung mot note.
- Ball tang size/speed theo config va phase.
- Trail/web visual cua `circle_bounce` hoat dong.
- Simulation dung khi het duration.
- Co error overlay cho config/audio critical error.
