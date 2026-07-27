# 05 - Output Folder Structure

## Muc tieu

Godot co the doc mot job folder ma khong can biet Python da xu ly nhu the nao.

## Cau truc job folder

```text
generated/jobs/job_001/
  video_config.json
  source_audio.wav
  metadata.json
  note_clips/
    note_0001.wav
    note_0002.wav
    note_0003.wav
```

## video_config.json

File quan trong nhat. Godot doc file nay de tao simulation.

## source_audio.wav

Ban audio da chuan hoa tu file goc. MVP co the luu de doi chieu.

## metadata.json

Thong tin phu:

```json
{
  "source_file": "input/songs/song_001.wav",
  "duration": 46.0,
  "sample_rate": 44100,
  "slice_mode": "manual_markers",
  "note_count": 180
}
```

## note_clips

Folder chua cac note clip.

Godot se load:

```text
note_clips_dir + note.file
```

trong `video_config.json`.
