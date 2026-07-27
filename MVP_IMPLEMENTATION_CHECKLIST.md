# MVP Implementation Checklist

## Muc tieu

Checklist nay bien cac tai lieu thiet ke thanh thu tu implement cu the, giu dung Clean Architecture va Clean Code.

## Nguyen tac chung

- Implement nho, verify tung buoc.
- Khong viet Godot logic trong Python.
- Khong viet audio slicing trong Godot.
- `shared/JSON_CONTRACT.md` va `shared/video_config.schema.json` la boundary chinh.
- Raw JSON chi nen nam o boundary loader/writer.
- Loi critical phai fail fast va noi ro nguyen nhan.

## Phase 1 - Shared contract

### Tasks

- Chot path convention cho `note_clips_dir`.
- Cap nhat `JSON_CONTRACT.md` theo convention do.
- Sieu chat `video_config.schema.json` voi color pattern va `audio_delay_ms >= 0`.
- Tao semantic validation rules trong Python sau khi co code.

### Done when

- Example config van pass schema.
- Contract noi ro field nao la required.
- Contract noi ro schema validation vs semantic validation.

## Phase 2 - Python domain and config generator

### Tasks

- Tao domain models:
  `AudioMetadata`, `NoteClip`, `SlicePlan`, `VideoConfig`, `Job`.
- Tao default preset cho video, `game_mode`, gameplay cua `circle_bounce`, visual, text, phases.
- Implement `GenerateVideoConfigUseCase`.
- Implement schema validator.
- Add test validate example config.

### Done when

- Tao duoc `VideoConfig` tu fake metadata va fake note clips.
- JSON output pass `shared/video_config.schema.json`.
- Phase mac dinh cover dung duration.

## Phase 3 - Python job output

### Tasks

- Implement `JobRepository`.
- Tao folder:
  `generated/jobs/job_xxx/`.
- Ghi `metadata.json`.
- Ghi `video_config.json`.
- Tao `note_clips/`.

### Done when

- Chay use case voi fake note clips tao dung folder structure.
- Khong hard-code path lung tung trong use case.

## Phase 4 - Python audio MVP

### Tasks

- Implement audio metadata reader cho `.wav`.
- Implement fixed interval slicing.
- Apply fade in/fade out 2-5 ms.
- Copy/convert source audio thanh `source_audio.wav`.
- Tao note files `note_0001.wav`, `note_0002.wav`.

### Done when

- Command MVP chay duoc voi `.wav`.
- Output co `source_audio.wav`, `metadata.json`, `video_config.json`, `note_clips/*.wav`.
- Config pass schema va semantic validation.

## Phase 5 - Python CLI

### Tasks

- Implement `main.py`.
- Implement `interface/cli.py`.
- Support command:
  `python main.py --input input/songs/song_001.wav --job job_001`.
- Support optional fixed interval:
  `--interval 0.2`.
- Return non-zero exit code khi loi critical.

### Done when

- CLI tao duoc job folder end-to-end.
- Loi input missing hien ro message.
- Invalid config khong duoc mark complete.

## Phase 6 - Godot base project

### Tasks

- Tao `project.godot`.
- Tao `Main.tscn`.
- Tao folder `scenes/` va `scripts/`.
- Implement `ConfigLoader.gd` doc `video_config.json`.
- Implement `VideoConfig.gd` wrapper.
- Implement `GameModeRegistry.gd` va `GameModeFactory.gd` voi mode dau tien `circle_bounce`.
- Implement error overlay toi thieu.

### Done when

- Godot load duoc example config.
- Unsupported `game_mode` show error thay vi crash.
- Config missing/invalid show error thay vi crash.

## Phase 7 - Godot circle_bounce mode

### Tasks

- Implement `SimulationController.gd` mode-agnostic.
- Implement `CircleBounceState.gd`.
- Implement `BallState.gd`.
- Implement `ArenaState.gd`.
- Implement `CircleBouncePhysics.gd`.
- Implement `CircleBounceModeController.gd`.
- Implement `CircleBounceView.gd`, `BallView.gd` va `ArenaView.gd`.
- Collision cooldown 10-30 ms.

### Done when

- Ball spawn dung config.
- Ball bay trong circle.
- Collision reflect dung.
- Hit count tang dung 1 lan moi collision.
- Radius/speed tang theo config va khong vuot cap.
- Runtime chung khong hard-code ball/circle; cac rule nay nam trong `circle_bounce`.

## Phase 8 - Godot audio trigger

### Tasks

- Implement `PathResolver.gd`.
- Implement `NoteSequence.gd`.
- Implement `NoteClipLoader.gd`.
- Implement `AudioNotePlayer.gd`.
- Connect signal `note_triggered`.
- Support `loop_notes` va `audio_delay_ms`.

### Done when

- Moi note trigger play note tiep theo.
- Het note va `loop_notes = true` thi quay lai note dau.
- Het note va `loop_notes = false` thi khong play note moi.
- Missing note clip show error/warning ro.

## Phase 9 - Godot visual MVP

### Tasks

- Implement `TrailRenderer.gd` cho `circle_bounce`.
- Support `short`, `long`, `web`.
- Implement rainbow trail.
- Implement impact ring.
- Implement `UIOverlay.gd`.
- Apply phase trail multiplier.

### Done when

- Web trail tao cam giac day dan.
- Impact effect xuat hien dung diem collision cua `circle_bounce`.
- Text top/bottom hien dung config.
- Visual khong che mat ball qua som trong intro.

## Phase 10 - Render and end-to-end demo

### Tasks

- Simulation dung khi `current_time >= video.duration`.
- Render theo `video.width`, `video.height`, `video.fps` neu Godot setup cho phep.
- Tao demo job bang Python.
- Load demo job trong Godot.
- Render thu video ngan 10-20 giay truoc, sau do render full duration.

### Done when

- End-to-end pipeline chay duoc:
  `song.wav -> Python job -> Godot simulation -> video render`.
- Audio note sync theo `note_triggered` cua active mode.
- Godot runtime chon mode theo `game_mode`.
- Video dung duration.
- Khong crash khi render full.

## Minimum quality bar

Truoc khi coi MVP hoan thanh:

- Python co test cho schema validation va config generator.
- Shared example config pass schema.
- Godot manual checklist pass.
- Error message ro rang cho missing config, invalid JSON, missing note clip.
- Folder output dung tai lieu.
- Khong co mot file nao gom qua nhieu trach nhiem.
