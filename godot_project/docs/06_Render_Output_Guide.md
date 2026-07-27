# 06 - Render Output Guide

## Muc tieu

Godot render video raw theo config, bat ke active game mode nao.

## Thong so render

Lay tu JSON:

```text
width
height
fps
duration
output_name
```

Mac dinh Shorts:

```text
1080x1920
60 fps
30-60 seconds
```

## Quy tac simulation time

Godot chay den khi:

```text
current_time >= video.duration
```

Sau do dung simulation va ket thuc render.

## Output folder

```text
output/godot_renders/
```

Output file:

```text
output/godot_renders/music_ball_001.mp4
```

Neu render image sequence:

```text
output/godot_renders/music_ball_001_frames/
  frame_000001.png
  frame_000002.png
```

## Luu y sync

- FPS render phai trung voi `video.fps`.
- Audio trigger theo `note_triggered` event cua active game mode.
- Neu render offline, can dam bao delta time on dinh.

## MVP

MVP chi can render truc tiep tu Godot editor hoac movie maker. Chua can Python goi Godot command line.
