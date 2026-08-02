# Godot Project

## Vai tro

Godot project la simulation engine va visual renderer.

Godot lam:

1. Doc `video_config.json`.
2. Chon game mode theo `game_mode`.
3. Tao scene, text, visual theo config va active mode.
4. Chay simulation cua active mode.
5. Khi active mode emit note trigger thi phat note tiep theo.
6. Render video raw.

Godot khong lam:

- Khong phan tich nhac.
- Khong cat note.
- Khong tao note clip.
- Khong sinh JSON config.

## Game mode dau tien

`circle_bounce` la mode dau tien:

- Ball bay trong circle arena.
- Wall collision tao note trigger.
- Ball tang size/speed theo hit.
- Trail/web/impact effect gan voi collision.

Khong hard-code cac rule nay vao runtime chung vi sau nay Godot se co nhieu game mode.

## Scene MVP cho circle_bounce

```text
Main.tscn
AudioNotePlayer.tscn
UIOverlay.tscn
modes/circle_bounce/CircleBounceMode.tscn
modes/circle_bounce/Ball.tscn
modes/circle_bounce/Arena.tscn
modes/circle_bounce/TrailRenderer.tscn
```

## Luong chay

```text
User chon video_config.json
  -> ConfigLoader doc JSON
  -> GameModeFactory chon mode theo game_mode
  -> SimulationController chay active mode
  -> Mode emit events/note_triggered
  -> AudioNotePlayer va mode visual phan ung event
  -> Render video raw
```

## Tai lieu thiet ke

- `docs/01_Godot_Project_Overview.md`: tong quan Godot runtime.
- `docs/02_Config_Loader_Design.md`: thiet ke loader/path resolver.
- `docs/03_Circle_Bounce_Mode_Rules.md`: rule physics va collision cua mode dau tien.
- `docs/04_Audio_Note_Trigger_System.md`: rule phat note theo note trigger cua active mode.
- `docs/05_Trail_And_Visual_System.md`: thiet ke visual/trail/impact.
- `docs/06_Render_Output_Guide.md`: quy tac render output.
- `docs/07_Clean_Architecture.md`: kien truc code, layer, signal, clean code va test checklist.
- `docs/10_YouTube_Shorts_CTR_Optimization.md`: huong dan dat tieu de video Shorts toi uu CTR cho kenh moi.
