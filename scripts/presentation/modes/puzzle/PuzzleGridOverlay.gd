# PuzzleGridOverlay.gd
class_name PuzzleGridOverlay
extends Node2D

const GRID_SIZE = 3
const CELL_SIZE = 160
const GRID_PIXEL = 480
const GRID_X = 300

var image_texture = null
var cell_nodes = []
var revealed = []
var total_cells = GRID_SIZE * GRID_SIZE
var reveal_count = 0
var is_complete = false
var reveal_target = 0
var phase_reveal_targets = [1, 3, 6, 9]

var top_text = null
var answer_label = null
var glow_timer = 0.0
var show_glow = false

func setup(p_image_path, p_top_text, p_job_folder):
	reveal_target = 0

	top_text = Label.new()
	top_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_text.add_theme_font_size_override("font_size", 28)
	top_text.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.9))
	top_text.text = p_top_text
	top_text.size = Vector2(GRID_PIXEL, GRID_PIXEL)
	top_text.position = Vector2.ZERO
	top_text.z_index = 100
	add_child(top_text)

	answer_label = Label.new()
	answer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	answer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	answer_label.add_theme_font_size_override("font_size", 32)
	answer_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0, 1.0))
	answer_label.size = Vector2(GRID_PIXEL, GRID_PIXEL)
	answer_label.position = Vector2.ZERO
	answer_label.z_index = 99
	answer_label.visible = false
	add_child(answer_label)

	if p_image_path != "":
		_load_image(p_image_path, p_job_folder)

	for r in range(GRID_SIZE):
		for c in range(GRID_SIZE):
			var idx = r * GRID_SIZE + c
			revealed.append(false)

			var cell = TextureRect.new()
			cell.size = Vector2(CELL_SIZE, CELL_SIZE)
			cell.position = Vector2(c * CELL_SIZE, r * CELL_SIZE)
			cell.z_index = 10

			if image_texture:
				var atlas = AtlasTexture.new()
				atlas.atlas = image_texture
				atlas.region = Rect2(Vector2(c * CELL_SIZE, r * CELL_SIZE), Vector2(CELL_SIZE, CELL_SIZE))
				cell.texture = atlas

			cell.modulate.a = 0.0
			cell.scale = Vector2(0.8, 0.8)
			cell.pivot_offset = Vector2(CELL_SIZE / 2.0, CELL_SIZE / 2.0)
			add_child(cell)
			cell_nodes.append(cell)

func _load_image(p_path, p_job_folder):
	var img = Image.new()
	var final_path = p_path
	if not final_path.begins_with("res://") and p_job_folder != "":
		final_path = p_job_folder.path_join(final_path)
	if not final_path.begins_with("res://"):
		final_path = "res://" + final_path
	var err = img.load(final_path)
	if err == OK:
		img.resize(GRID_PIXEL, GRID_PIXEL, Image.INTERPOLATE_LANCZOS)
		image_texture = ImageTexture.create_from_image(img)

func reveal_cells(count):
	var unrevealed = []
	for i in range(total_cells):
		if not revealed[i]:
			unrevealed.append(i)

	unrevealed.shuffle()
	for j in range(min(count, unrevealed.size())):
		var idx = unrevealed[j]
		revealed[idx] = true
		reveal_count += 1

		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(cell_nodes[idx], "modulate:a", 1.0, 0.25).set_ease(Tween.EASE_OUT)
		tween.tween_property(cell_nodes[idx], "scale", Vector2(1.0, 1.0), 0.25).set_ease(Tween.EASE_OUT)

	if reveal_count >= total_cells:
		is_complete = true
		_hide_top_text()
		_trigger_complete_glow()

func reveal_by_phase(current_time, duration, phases):
	if is_complete or duration <= 0.0:
		return

	var ratio = clampf(current_time / duration, 0.0, 1.0)

	var phase_idx = 0
	if not phases.is_empty():
		for p in range(phases.size()):
			var end_time = float(phases[p].get("end_time", 0.0))
			if current_time >= end_time:
				phase_idx = p

	var target = phase_reveal_targets[min(phase_idx, phase_reveal_targets.size() - 1)]
	target = min(target, total_cells)

	while reveal_target < target:
		reveal_target += 1
		reveal_cells(1)

func reveal_all():
	for i in range(total_cells):
		if not revealed[i]:
			revealed[i] = true
			reveal_count += 1
			cell_nodes[i].modulate.a = 1.0
			cell_nodes[i].scale = Vector2(1.0, 1.0)
	is_complete = true
	_hide_top_text()
	_trigger_complete_glow()

func _hide_top_text():
	var tween = create_tween()
	tween.tween_property(top_text, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): top_text.visible = false)

func show_answer(p_song_name):
	answer_label.text = p_song_name
	answer_label.modulate.a = 0.0
	answer_label.visible = true
	var tween = create_tween()
	tween.tween_property(answer_label, "modulate:a", 1.0, 0.5).set_ease(Tween.EASE_OUT)

func _trigger_complete_glow():
	show_glow = true
	glow_timer = 1.0

func _process(delta):
	if show_glow:
		glow_timer -= delta
		if glow_timer <= 0.0:
			show_glow = false
		queue_redraw()

func _draw():
	if not show_glow:
		return

	var progress = 1.0 - (glow_timer / 1.0)
	var alpha = sin(progress * PI * 2.0) * 0.4 + 0.3
	var hue = wrapf(progress * 0.5, 0.0, 1.0)
	var col = Color.from_hsv(hue, 0.8, 1.0, alpha)
	var rect = Rect2(Vector2(GRID_X - 8, 0), Vector2(GRID_PIXEL + 16, GRID_PIXEL))
	draw_rect(rect, col, false, 4.0)
