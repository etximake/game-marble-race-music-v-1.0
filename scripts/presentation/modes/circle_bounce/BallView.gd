# BallView.gd
class_name BallView
extends Node2D

var state: BallState
var color: Color = Color.WHITE
var use_glow: bool = true
var use_rainbow: bool = true
var time_elapsed: float = 0.0

var pulse_scale: float = 1.0
var pulse_timer: float = 0.0
const MAX_SPEED_DEFAULT: float = 1600.0

var ball_icon_texture: Texture2D = null
var use_ball_icon: bool = false
var icon_silhouette_mode: bool = false
var icon_reveal_phase: String = "final_storm"
var icon_rotation_mode: String = "none"
var reveal_time: float = -1.0
var phases_list: Array = []
var is_time_synced_externally: bool = false

func setup(p_state: BallState, visual_config: Dictionary, job_folder: String = "", phases: Array = []):
	state = p_state
	color = Color.from_string(visual_config.get("ball_color", "#00ffcc"), Color.WHITE)
	use_glow = visual_config.get("use_glow", true)
	use_rainbow = visual_config.get("use_rainbow_trail", true)
	
	use_ball_icon = visual_config.get("use_ball_icon", false)
	var ball_icon_path = visual_config.get("ball_icon_path", "")
	icon_silhouette_mode = visual_config.get("icon_silhouette_mode", false)
	icon_reveal_phase = visual_config.get("icon_reveal_phase", "final_storm")
	icon_rotation_mode = visual_config.get("icon_rotation_mode", "none")
	
	phases_list = phases
	reveal_time = -1.0
	for phase in phases:
		if phase.get("name", "") == icon_reveal_phase:
			reveal_time = float(phase.get("start_time", 0.0))
			break
			
	if use_ball_icon and ball_icon_path != "":
		var resolved_path = PathResolver.resolve_path(job_folder, ball_icon_path)
		if FileAccess.file_exists(resolved_path):
			if resolved_path.begins_with("res://"):
				ball_icon_texture = load(resolved_path) as Texture2D
			else:
				var img = Image.load_from_file(resolved_path)
				if img:
					ball_icon_texture = ImageTexture.create_from_image(img)
					
	queue_redraw()

func trigger_pulse():
	pulse_scale = 1.12
	pulse_timer = 0.15

func _process(delta: float):
	if state:
		position = state.position
		if not is_time_synced_externally:
			time_elapsed += delta
		if pulse_timer > 0.0:
			pulse_timer -= delta
			var t = 1.0 - (pulse_timer / 0.15)
			pulse_scale = lerpf(1.12, 1.0, t * t)
			if pulse_timer <= 0.0:
				pulse_scale = 1.0
		queue_redraw()

func _draw():
	if not state:
		return

	var radius = state.radius * pulse_scale

	# 1. Outer sharp black stroke
	draw_circle(Vector2.ZERO, radius, Color(0.0, 0.0, 0.0, 1.0))
	
	if use_ball_icon:
		var should_reveal = (reveal_time < 0.0) or (time_elapsed >= reveal_time)

		var rotation_angle = 0.0
		if icon_rotation_mode == "velocity" and state.velocity != Vector2.ZERO:
			rotation_angle = state.velocity.angle() + PI / 2.0
		elif icon_rotation_mode == "spin":
			rotation_angle = time_elapsed * 3.0

		if rotation_angle != 0.0:
			draw_set_transform(Vector2.ZERO, rotation_angle, Vector2.ONE)

		if not should_reveal:
			if icon_silhouette_mode:
				if ball_icon_texture:
					var size = (radius - 2.5) * 2.0
					var dest_rect = Rect2(-radius + 2.5, -radius + 2.5, size, size)
					draw_texture_rect(ball_icon_texture, dest_rect, false, Color(0.0, 0.0, 0.0, 1.0))
				else:
					_draw_question_placeholder(radius, Color(0.0, 0.0, 0.0, 1.0))
			else:
				_draw_question_placeholder(radius, Color.WHITE)
		else:
			if ball_icon_texture:
				var size = (radius - 2.5) * 2.0
				var dest_rect = Rect2(-radius + 2.5, -radius + 2.5, size, size)
				draw_texture_rect(ball_icon_texture, dest_rect, false)
			else:
				_draw_question_placeholder(radius, Color.WHITE)

		if rotation_angle != 0.0:
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

		for i in range(8):
			var t = float(i + 1) / 8.0
			var r_level = (radius - 2.5) * (1.0 - t * 0.1)
			var c_alpha = t * 0.07
			draw_circle(Vector2.ZERO, r_level, Color(1.0, 1.0, 1.0, c_alpha))

		draw_circle(Vector2.ZERO, radius * 0.52, Color(1.0, 1.0, 1.0, 0.18))
		draw_circle(Vector2.ZERO, radius * 0.36, Color(1.0, 1.0, 1.0, 0.30))
		draw_circle(Vector2.ZERO, radius * 0.22, Color(1.0, 1.0, 1.0, 0.65))
		
	else:
		var draw_col = color
		if use_rainbow:
			var pos_hue = wrapf(state.position.x * 0.0003 + state.position.y * 0.0004, 0.0, 1.0)
			var dir_hue = wrapf((state.velocity.angle() + PI) / TAU, 0.0, 1.0)
			var time_hue = wrapf(time_elapsed * 0.06, 0.0, 1.0)
			var hue = wrapf(pos_hue * 0.4 + dir_hue * 0.3 + time_hue * 0.3, 0.0, 1.0)
			draw_col = Color.from_hsv(hue, 0.85, 0.9)

		# Solid green body base
		var ball_base_col = Color(0.0, 0.75, 0.1) # Vibrant Green as reference image
		draw_circle(Vector2.ZERO, radius - 2.5, ball_base_col)
		
		# Radial gradient layers fading into bright center
		for i in range(8):
			var t = float(i + 1) / 8.0
			var r_level = (radius - 2.5) * (1.0 - t * 0.1)
			var c_alpha = t * 0.18
			draw_circle(Vector2.ZERO, r_level, Color(0.1, 0.9, 0.2, c_alpha))

		# Soft center inner glow ring
		draw_circle(Vector2.ZERO, radius * 0.52, Color(0.65, 0.98, 0.55, 0.75))
		draw_circle(Vector2.ZERO, radius * 0.36, Color(0.85, 1.0, 0.78, 0.90))
		# White highlight center
		draw_circle(Vector2.ZERO, radius * 0.22, Color(1.0, 1.0, 1.0, 0.98))

func _draw_question_placeholder(radius: float, modulate_color: Color) -> void:
	var face_color = Color(0.55, 0.27, 0.68) # Beautiful quiz purple #8e44ad
	var question_color = Color(1.0, 1.0, 1.0) # White
	
	if modulate_color == Color(0.0, 0.0, 0.0, 1.0):
		face_color = Color(0.0, 0.0, 0.0, 1.0)
		question_color = Color(0.0, 0.0, 0.0, 1.0)
		
	draw_circle(Vector2.ZERO, radius - 2.5, face_color)
	
	if face_color != Color.BLACK:
		var font = load("res://assets/fonts/Montserrat-ExtraBold.ttf") as Font
		if not font:
			font = ThemeDB.fallback_font
		if font:
			var font_size = int(radius * 1.4)
			var text = "?"
			var ascent = font.get_ascent(font_size)
			var descent = font.get_descent(font_size)
			var pos = Vector2(-radius, (ascent - descent) * 0.5 - radius * 0.05)
			draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0, font_size, question_color)
