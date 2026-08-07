# PuzzleGridOverlay.gd
class_name PuzzleGridOverlay
extends Node2D

const ALBUM_SIZE = 640
const REVEAL_SLICES = 8

var image_texture: Texture2D = null
var revealed: Array = []
var reveal_count: int = 0
var total_cells: int = REVEAL_SLICES
var is_complete: bool = false

var spin_angle: float = 0.0
var show_glow: bool = false
var glow_timer: float = 0.0

var flash_timers: Array = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
var flash_durations: Array = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
var last_flash_color: Color = Color.WHITE

var current_time: float = 0.0
var reveal_time: float = 20.0
var video_duration: float = 30.0
var reveal_start_time: float = 3.0
var reveal_interval: float = 2.0
var next_reveal_at: float = 0.0

var is_reveal_animating: bool = false
var reveal_anim_timer: float = 0.0
var reveal_anim_spin_speed: float = 0.0
var reveal_anim_flash: float = 0.0

var center_offset: Vector2 = Vector2(540, 1060)

func setup(p_image_path: String, p_top_text: String, p_job_folder: String, p_reveal_time: float = 20.0, p_duration: float = 30.0):
	reveal_count = 0
	is_complete = false
	revealed.clear()
	for i in range(REVEAL_SLICES):
		revealed.append(false)

	flash_timers = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	flash_durations = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	last_flash_color = Color.WHITE

	current_time = 0.0
	reveal_time = p_reveal_time
	video_duration = p_duration

	var reveal_window = max(reveal_time - reveal_start_time - 3.0, 4.0)
	reveal_interval = reveal_window / float(REVEAL_SLICES)
	next_reveal_at = reveal_start_time + reveal_interval

	is_reveal_animating = false
	reveal_anim_timer = 0.0
	reveal_anim_spin_speed = 0.0
	reveal_anim_flash = 0.0

	if p_image_path != "":
		_load_image(p_image_path, p_job_folder)

	position = Vector2.ZERO
	z_index = 2

func _load_image(p_path: String, p_job_folder: String):
	var img = Image.new()
	var final_path = p_path
	if not final_path.begins_with("res://") and p_job_folder != "":
		final_path = p_job_folder.path_join(final_path)
	if not final_path.begins_with("res://"):
		final_path = "res://" + final_path
	var err = img.load(final_path)
	if err == OK:
		img.resize(ALBUM_SIZE, ALBUM_SIZE, Image.INTERPOLATE_LANCZOS)
		image_texture = ImageTexture.create_from_image(img)

func reveal_cells(count: int):
	var unrevealed = []
	for i in range(total_cells):
		if not revealed[i]:
			unrevealed.append(i)

	unrevealed.shuffle()
	for j in range(min(count, unrevealed.size())):
		var idx = unrevealed[j]
		revealed[idx] = true
		reveal_count += 1

	if reveal_count >= total_cells:
		is_complete = true
		_trigger_complete_glow()

func flash_slice_at_angle(collision_angle: float, p_current_time: float, phases: Array, flash_color: Color):
	if is_complete:
		return

	var phase_idx = 0
	if not phases.is_empty():
		for p in range(phases.size()):
			var end_time = float(phases[p].get("end_time", 0.0))
			if p_current_time >= end_time:
				phase_idx = p

	var phase_name = ""
	if not phases.is_empty() and phase_idx < phases.size():
		phase_name = phases[phase_idx].get("name", "")

	var flash_dur = 0.60
	var count = 1
	if phase_name == "intro":
		flash_dur = 0.60
		count = 1
	elif phase_name == "build_up":
		flash_dur = 0.50
		count = 2
	elif phase_name == "final_storm":
		flash_dur = 0.40
		count = 3
	else:
		flash_dur = 0.40
		count = 3

	var local_angle = collision_angle - spin_angle
	local_angle = wrapf(local_angle, 0.0, TAU)

	var slice_angle = TAU / REVEAL_SLICES
	var center_slice = int(local_angle / slice_angle) % REVEAL_SLICES

	last_flash_color = flash_color

	var slices_to_flash = []
	slices_to_flash.append(center_slice)
	if count >= 2:
		slices_to_flash.append((center_slice + 1) % REVEAL_SLICES)
	if count >= 3:
		slices_to_flash.append((center_slice - 1 + REVEAL_SLICES) % REVEAL_SLICES)

	for idx in slices_to_flash:
		flash_timers[idx] = flash_dur
		flash_durations[idx] = flash_dur

func reveal_all():
	reveal_all_with_animation()

func reveal_all_with_animation():
	if is_complete:
		return
	for i in range(total_cells):
		revealed[i] = true
	reveal_count = total_cells
	is_complete = true
	is_reveal_animating = true
	reveal_anim_timer = 0.8
	reveal_anim_spin_speed = deg_to_rad(120.0)
	reveal_anim_flash = 1.0
	_trigger_complete_glow()

func _trigger_complete_glow():
	show_glow = true
	glow_timer = 1.0

func _process(delta: float):
	if is_reveal_animating:
		reveal_anim_timer -= delta
		if reveal_anim_timer <= 0.0:
			reveal_anim_timer = 0.0
			is_reveal_animating = false
			reveal_anim_spin_speed = 0.0
			reveal_anim_flash = 0.0
		else:
			var t = 1.0 - (reveal_anim_timer / 0.8)
			reveal_anim_spin_speed = lerpf(deg_to_rad(120.0), deg_to_rad(15.0), t * t)
			reveal_anim_flash = lerpf(1.0, 0.0, t)

	var spin_speed = deg_to_rad(15.0)
	if is_reveal_animating:
		spin_speed = reveal_anim_spin_speed
	spin_angle += spin_speed * delta
	if spin_angle > TAU:
		spin_angle -= TAU

	for i in range(REVEAL_SLICES):
		if flash_timers[i] > 0.0:
			flash_timers[i] -= delta
			if flash_timers[i] < 0.0:
				flash_timers[i] = 0.0

	if show_glow:
		glow_timer -= delta
		if glow_timer <= 0.0:
			show_glow = false

	if not is_complete and current_time >= next_reveal_at and current_time < reveal_time - 3.0:
		reveal_cells(1)
		next_reveal_at += reveal_interval

	queue_redraw()

func _draw():
	var radius = ALBUM_SIZE / 2.0

	draw_circle(center_offset, radius, Color(0.06, 0.06, 0.08, 0.95))

	for i in range(6):
		var r = radius - 15.0 - float(i) * 30.0
		if r > 40.0:
			draw_arc(center_offset, r, 0, TAU, 180, Color(0.18, 0.18, 0.22, 0.4), 1.0, true)

	if image_texture:
		draw_set_transform(center_offset, spin_angle, Vector2.ONE)

		var label_r = 280.0
		var label_size = label_r * 2.0
		var rect = Rect2(-label_r, -label_r, label_size, label_size)

		draw_texture_rect(image_texture, rect, false)

		if is_reveal_animating and reveal_anim_flash > 0.01:
			draw_circle(Vector2.ZERO, label_r, Color(1.0, 1.0, 1.0, reveal_anim_flash * 0.6))

		var slice_angle = TAU / REVEAL_SLICES
		for i in range(REVEAL_SLICES):
			if not revealed[i]:
				var points = PackedVector2Array()
				points.append(Vector2.ZERO)
				var start_a = float(i) * slice_angle
				var end_a = float(i + 1) * slice_angle
				var steps = 12
				for step in range(steps + 1):
					var a = start_a + (end_a - start_a) * (float(step) / float(steps))
					points.append(Vector2(cos(a), sin(a)) * label_r)

				var overlay_alpha = 1.0
				if flash_timers[i] > 0.0 and flash_durations[i] > 0.0:
					var t = flash_timers[i] / flash_durations[i]
					overlay_alpha = lerpf(1.0, 0.0, t)

				draw_polygon(points, PackedColorArray([Color(0.05, 0.05, 0.07, overlay_alpha)]))

				if flash_timers[i] > 0.0 and flash_durations[i] > 0.0:
					var t = flash_timers[i] / flash_durations[i]
					if t > 0.7:
						var neon_strength = (t - 0.7) / 0.3
						var glow_color_mod = Color(last_flash_color.r, last_flash_color.g, last_flash_color.b, neon_strength * 0.55)
						draw_polygon(points, PackedColorArray([glow_color_mod]))

				draw_line(Vector2.ZERO, Vector2(cos(start_a), sin(start_a)) * label_r, Color(0.02, 0.02, 0.04, 0.5 * overlay_alpha), 1.5, true)

		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

		draw_circle(center_offset, 24.0, Color(0.1, 0.1, 0.12, 1.0))
		draw_circle(center_offset, 10.0, Color(0.02, 0.02, 0.02, 1.0))
		draw_arc(center_offset, 24.0, 0, TAU, 64, Color(0.5, 0.5, 0.55, 0.8), 2.0, true)

	if show_glow:
		var progress = 1.0 - (glow_timer / 1.0)
		var alpha = sin(progress * PI * 2.0) * 0.4 + 0.4
		var hue = wrapf(progress * 0.5, 0.0, 1.0)
		var col = Color.from_hsv(hue, 0.9, 1.0, alpha)
		draw_arc(center_offset, radius + 4.0, 0, TAU, 180, col, 6.0, true)