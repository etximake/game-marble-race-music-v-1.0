# Shared Contract

## Vai tro

`shared` chua contract du lieu dung chung giua Python project va Godot project.

Python tao `video_config.json` va snapshot `gameplay_config.json` trong moi job.

Godot doc cap hai file trong cung job folder theo contract nay.

## Tai lieu va file chinh

- `JSON_CONTRACT.md`: mo ta format `video_config.json`.
- `video_config.schema.json`: JSON Schema validate shape/type/required field.
- `gameplay_template.json`: preset dau vao cho snapshot `circle_bounce`.
- `gameplay_template_polygon.json`: preset dau vao cho snapshot `polygon_bounce`.
- `VALIDATION_RULES.md`: rule validate schema va semantic rules.

## Nguyen tac

- Shared khong chua logic runtime.
- Shared khong phu thuoc Python implementation.
- Shared khong phu thuoc Godot implementation.
- Moi thay doi contract can xem lai ca Python generator va Godot loader.
