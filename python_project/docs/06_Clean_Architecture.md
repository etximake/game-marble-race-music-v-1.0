# 06 - Clean Architecture

Python project la pipeline chuan bi Job Music JSON cho Godot.

```text
interface -> application -> domain
infrastructure -> application/domain qua service/repository
```

## Domain

Chua metadata audio, note clip, slice plan, job music config va domain errors.

## Application

`GenerateJobUseCase` dieu phoi:

```text
read metadata
normalize audio
slice note clips
generate Job Music JSON
validate Job Music JSON
write job output
```

## Infrastructure

- Pydub audio service.
- Pydub audio slicer.
- Filesystem job repository.
- JSON Schema validator.

## Contract boundary

Python chi ghi:

```text
video.duration
video.output_name
text
job_assets
```

Python snapshot gameplay preset vao `gameplay_config.json`; Godot doc snapshot nay:

```text
game_mode
video.width/height/fps
visual
quiz
timeline
phases
```

Godot merge hai nguon thanh runtime `VideoConfig`. Quiz, icon reveal, hit count, ball evolution va final storm la logic Godot, khong thuoc Python audio pipeline.
