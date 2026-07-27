# 02 - Config Loader Design

## Muc tieu

Doc ca `video_config.json` (chua du lieu bai hat: note list, duration, output name) va `gameplay_template.json` (chua cau hinh gameplay, visual, phases cua he thong) va gop chung (merge) lai tai runtime. Loader khong chon game mode truc tiep; application layer dung `VideoConfig.get_game_mode()` de chon mode.

## Module de xuat

```text
ConfigLoader.gd
VideoConfig.gd
PathResolver.gd
```

## ConfigLoader.gd

Trach nhiem:

- Doc va parse file JSON data bai hat (`video_config.json` từ job folder).
- Doc va parse file JSON template chung (`gameplay_template.json` tu shared/ hoac duong dan duoc chi dinh).
- Gop de (Deep Merge) du lieu job vao ban sao cua template.
- Tu dong gian ty le: gán `end_time` cua phase cuoi cung (`final_storm`) bang dung thoi luong `duration` cua bai hat.
- Kiem tra field bat buoc tren merged config.
- Tra ve VideoConfig object/dictionary da duoc gop.

## VideoConfig.gd

Trach nhiem:

- Luu config merged.
- Cung cap helper function:
  - get_project_version()
  - get_game_mode()
  - get_video_width()
  - get_duration()
  - get_gameplay_config()
  - get_audio_notes()
  - get_current_phase(time)

## PathResolver.gd

Trach nhiem:

- Resolve duong dan note clip.
- Ho tro duong dan tuong doi theo job folder.

Vi du:

```text
job folder: generated/jobs/job_001/
note_clips_dir: generated/jobs/job_001/note_clips/
note file: note_0001.wav
full path: generated/jobs/job_001/note_clips/note_0001.wav
```

## Xu ly loi

Neu thieu file JSON:

```text
Show error: Cannot find video_config.json / gameplay_template.json
```

Neu JSON sai format:

```text
Show error: Invalid video_config.json / gameplay_template.json
```

Neu `game_mode` khong duoc support:

```text
Show error: Unsupported game_mode
```

Neu note clip thieu:

```text
Show warning va skip note hoac dung simulation tuy mode.
```
