# 01 - Python Project Overview

## Muc tieu

Python project la cong cu tao du lieu dau vao cho Godot.

Input chinh la mot file nhac. Output chinh la:

- Folder note clips.
- File `video_config.json`.

## Luong xu ly

```text
song.wav
  -> audio_loader
  -> audio_slicer
  -> note_map_generator
  -> config_generator
  -> schema_validator
  -> generated/jobs/job_xxx/
```

## Module can code

```text
audio_loader.py
  - doc file audio
  - lay duration
  - convert ve wav neu can

audio_slicer.py
  - cat audio thanh note clips
  - ho tro manual markers, onset detect, fixed interval

note_map_generator.py
  - tao danh sach note theo thu tu
  - dat ten file note_0001.wav, note_0002.wav

config_generator.py
  - tao video_config.json
  - gan default game_mode, gameplay cua mode dau tien, visual, text, phases

schema_validator.py
  - validate JSON theo shared/video_config.schema.json
```

## Nguyen tac MVP

MVP nen uu tien lam dung va on dinh, khong can automation phuc tap.

- Mot bai nhac tao mot job folder.
- Mot job folder co mot `video_config.json`.
- Godot doc truc tiep job folder do.
