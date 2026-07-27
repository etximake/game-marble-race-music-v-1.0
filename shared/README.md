# Shared Contract

## Vai tro

`shared` chua contract du lieu dung chung giua Python project va Godot project.

Python tao `video_config.json` theo contract nay.

Godot doc `video_config.json` theo contract nay.

## Tai lieu va file chinh

- `JSON_CONTRACT.md`: mo ta format `video_config.json`.
- `video_config.schema.json`: JSON Schema validate shape/type/required field.
- `example_video_config.json`: config mau.
- `gameplay_template.json`: template mac dinh cho `circle_bounce` mode.
- `gameplay_template_polygon.json`: template cho `polygon_bounce` mode.
- `VALIDATION_RULES.md`: rule validate schema va semantic rules.

## Nguyen tac

- Shared khong chua logic runtime.
- Shared khong phu thuoc Python implementation.
- Shared khong phu thuoc Godot implementation.
- Moi thay doi contract can xem lai ca Python generator va Godot loader.
