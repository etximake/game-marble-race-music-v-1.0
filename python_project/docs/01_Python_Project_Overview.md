# 01 - Python Project Overview

## Muc tieu

Python project la cong cu tao du lieu dau vao cho Godot.

Input chinh la mot file nhac. Output chinh la:

- Folder note clips.
- File `video_config.json`.
- File `gameplay_config.json` snapshot tu gameplay template.

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
  - tao Job Music JSON gom duration, output name, audio notes, text va job assets

gameplay_snapshot_writer
  - copy shared/gameplay_template.json vao gameplay_config.json cua job

schema_validator.py
  - validate JSON theo shared/video_config.schema.json
```

## Nguyen tac MVP

MVP nen uu tien lam dung va on dinh, khong can automation phuc tap.

- Mot bai nhac tao mot job folder.
- Mot job folder co `video_config.json` va `gameplay_config.json`.
- `job_profile.json` quy dinh input, duration va slicing.
- Godot doc cap config tu cung mot job folder.
