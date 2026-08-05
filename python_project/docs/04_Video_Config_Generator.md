# 04 - Job Music JSON Generator

## Muc tieu

Tao du lieu rieng cua mot job am thanh de Godot merge voi `shared/gameplay_template.json`.
Python khong sinh gameplay, visual, game mode hoac phases.

## Output

```text
generated/jobs/job_001/video_config.json
generated/jobs/job_001/gameplay_config.json
```

File Job Music JSON gom:

```text
video.duration
video.output_name
text
job_assets
```

## Ownership

Python so huu:

- duration cua audio.
- ten output cua job.
- note clips va thu tu phat.
- audio delay/loop settings.
- noi dung text cua video.
- asset rieng cua job, vi du duong dan logo ball.

Godot template so huu:

- game_mode.
- width, height, fps.
- ball/arena physics.
- visual behavior.
- phases va cac multiplier tien hoa.

## Audio settings

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

Moi note la mot clip doc lap. Godot phat mot clip khi mode tao `note_triggered`.

## Validation

Python validate Job Music JSON bang:

```text
shared/video_config.schema.json
```

Validator kiem tra duration (tu 1.0 den 60.0 giay), danh sach notes, index lien tuc, va truong `quiz` (neu co). Gameplay va phase duoc validate sau khi Godot merge voi template.

## Quiz settings

Doi voi che do Puzzle, file JSON sinh ra chua thong tin quiz dung de dieu khien hien thi cau hoi/dap an va qua trinh mo cac manh ghep dia than:

```json
"quiz": {
  "prompt": "Guess this song from\n the satisfying beats! ✨",
  "reveal_time": 20.0,
  "enabled": true
}
```

Trong do:
- `prompt`: cau hoi doan ten bai hat hien thi tai Header.
- `reveal_time`: thoi diem tu dong mo toan bo dia nhac (mac dinh bang `duration - 6.0` doi voi Puzzle).
- `enabled`: bat/tat tinh nang quiz.

## Short video profile

Job production nen co duration tu 20 den 25 giay, mac dinh 22 giay. Audio source
duoc cat truoc khi slicing de source_audio.wav, note clips va video.duration
luon dung cung mot timeline. Godot dat intro 2 giay, build-up den khoang 73%
duration va final storm o phan cuoi.

Thoi luong va slicing duoc dat trong `python_project/job_profile.json`, khong
hard-code trong `main.py`. Gameplay template luu timeline policy:
`intro_duration_seconds`, `build_up_end_ratio`, va `reveal_ratio`.

Python copy gameplay template thanh `gameplay_config.json` trong chinh job
folder. Moi job vi vay co snapshot gameplay rieng.

Tao job khac bang profile khac:

```text
python main.py --profile job_profile_002.json
```

Godot tu doc `gameplay_config.json` nam canh `video_config.json` trong job.
