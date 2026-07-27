# Music Ball Video Engine - Design Docs

## Muc tieu

Du an nay tao video dang music game/simulation cho YouTube Shorts/TikTok. Mode dau tien la music bouncing ball (`circle_bounce`):

- Python project nhap bai nhac, cat thanh cac note clip nho, tao `video_config.json`.
- Godot project doc `video_config.json`, chon `game_mode`, chay active mode, phat note theo trigger, ve visual, render video raw.

## Workflow MVP

```text
input song
  -> Python project
  -> generated/jobs/job_001/note_clips/
  -> generated/jobs/job_001/video_config.json
  -> User mo Godot
  -> Godot doc video_config.json
  -> Godot render video raw
```

## Ranh gioi trach nhiem

Python lam:

1. Nhap bai nhac.
2. Cat bai nhac thanh `note_0001.wav`, `note_0002.wav`, ...
3. Tao `video_config.json`.

Godot lam:

1. Doc `video_config.json`.
2. Chon active mode theo `game_mode`.
3. Tao scene/visual theo config va mode.
4. Khi active mode emit note trigger thi phat note tiep theo.
5. Render video raw.

## File trung tam

File trung tam la:

```text
generated/jobs/job_001/video_config.json
```

Moi thay doi giua Python va Godot phai thong qua file nay.

## Tai lieu kien truc

- `MVP_IMPLEMENTATION_CHECKLIST.md`: thu tu trien khai MVP theo Clean Architecture.
- `shared/README.md`: tong quan shared contract.
- `shared/VALIDATION_RULES.md`: schema validation va semantic validation cho `video_config.json`.
- `python_project/docs/06_Clean_Architecture.md`: kien truc code Python project.
- `godot_project/docs/07_Clean_Architecture.md`: kien truc code Godot project.
