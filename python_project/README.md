# Python Project

## Vai tro

Python project chuan bi du lieu cho Godot.

Python lam:

1. Nhap bai nhac.
2. Chuan hoa audio neu can.
3. Cat nhac thanh cac note clip nho.
4. Tao `video_config.json`.
5. Validate JSON theo schema.

Python khong lam:

- Khong render video.
- Khong chay simulation.
- Khong xu ly collision.
- Khong tao visual effect trong game.

## Input

```text
input/songs/song_001.wav
```

## Output

```text
generated/jobs/job_001/
  video_config.json
  source_audio.wav
  note_clips/
    note_0001.wav
    note_0002.wav
    note_0003.wav
  metadata.json
```

## Command MVP du kien

```bash
python main.py --input input/songs/song_001.wav --job job_001
```

## Tai lieu thiet ke

- `docs/01_Python_Project_Overview.md`: tong quan Python pipeline.
- `docs/02_Audio_Input_Rules.md`: quy tac input audio.
- `docs/03_Note_Slicing_System.md`: thiet ke cat note clips.
- `docs/04_Video_Config_Generator.md`: thiet ke tao `video_config.json`.
- `docs/05_Output_Folder_Structure.md`: cau truc job output.
- `docs/06_Clean_Architecture.md`: kien truc code, layer, use case, clean code va test strategy.
