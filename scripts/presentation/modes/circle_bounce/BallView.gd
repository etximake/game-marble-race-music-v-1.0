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

const QUIZ_PALETTE: Array = [
	{ "bg": Color(0.08, 0.02, 0.18), "text": Color(1.0, 0.84, 0.0) },
	{ "bg": Color(0.02, 0.08, 0.20), "text": Color(0.0, 1.0, 0.85) },
	{ "bg": Color(0.18, 0.04, 0.04), "text": Color(1.0, 0.3, 0.55) },
	{ "bg": Color(0.04, 0.15, 0.12), "text": Color(0.4, 1.0, 0.35) },
	{ "bg": Color(0.15, 0.06, 0.02), "text": Color(1.0, 0.55, 0.1) },
	{ "bg": Color(0.02, 0.10, 0.18), "text": Color(0.2, 0.75, 1.0) },
	{ "bg": Color(0.14, 0.02, 0.14), "text": Color(1.0, 0.45, 0.9) },
	{ "bg": Color(0.03, 0.16, 0.18), "text": Color(0.3, 1.0, 0.95) },
]
var quiz_bg_color: Color = Color(0.07, 0.07, 0.09)
var quiz_text_color: Color = Color.WHITE

func setup(p_state: BallState, visual_config: Dictionary, job_folder: String = "", phases: Array = [], quiz_config: Dictionary = {}):
	state = p_state
	color = Color.from_string(visual_config.get("ball_color", "#00ffcc"), Color.WHITE)
	use_glow = visual_config.get("use_glow", true)
	use_rainbow = visual_config.get("use_rainbow_trail", true)
	z_index = 5
	
	use_ball_icon = visual_config.get("use_ball_icon", false)
	var ball_icon_path = visual_config.get("ball_icon_path", "")
	icon_silhouette_mode = visual_config.get("icon_silhouette_mode", false)
	icon_reveal_phase = visual_config.get("icon_reveal_phase", "final_storm")
	icon_rotation_mode = visual_config.get("icon_rotation_mode", "none")
	
	phases_list = phases
	reveal_time = float(quiz_config.get("reveal_time", -1.0))
	if not bool(quiz_config.get("enabled", true)):
		reveal_time = 0.0
	for phase in phases:
		if reveal_time < 0.0 and phase.get("name", "") == icon_reveal_phase:
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
	
	var pair = QUIZ_PALETTE[randi() % QUIZ_PALETTE.size()]
	quiz_bg_color = pair["bg"]
	quiz_text_color = pair["text"]
	
	queue_redraw()

func trigger_pulse(phase_name: String = ""):
	# Co giãn theo phase để tăng độ thỏa mãn thị giác (intro: 1.06, build_up: 1.12, final_storm/climax: 1.25)
	var max_pulse = 1.12
	if phase_name == "intro":
		max_pulse = 1.06
	elif phase_name == "build_up":
		max_pulse = 1.12
	elif phase_name == "final_storm" or phase_name == "climax_storm":
		max_pulse = 1.25
		
	pulse_scale = max_pulse
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

	# 1. Outer sharp black stroke to separate the ball from the trail
	draw_circle(Vector2.ZERO, radius, Color(0.0, 0.0, 0.0, 1.0))
	
	# 2. Dynamic Neon glow color synced with rainbow trail
	var glow_col = color
	if use_rainbow:
		var hue = wrapf(time_elapsed * 0.25, 0.0, 1.0)
		glow_col = Color.from_hsv(hue, 1.0, 1.0)

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
			draw_circle(Vector2.ZERO, radius - 2.5, quiz_bg_color)
			
			# Sleek neon outline rings
			draw_arc(Vector2.ZERO, radius - 3.5, 0.0, TAU, 96, glow_col, 2.5, true)
			draw_arc(Vector2.ZERO, radius - 3.5, 0.0, TAU, 96, Color(glow_col.r, glow_col.g, glow_col.b, 0.3), 5.5, true)
			
			if icon_silhouette_mode:
				_draw_quiz_question(radius, glow_col)
			else:
				_draw_question_placeholder(radius, glow_col)
		else:
			# Clean reveal: logo takes up the space with no distracting layers
			if ball_icon_texture:
				var size = (radius - 2.5) * 2.0
				var dest_rect = Rect2(-radius + 2.5, -radius + 2.5, size, size)
				draw_texture_rect(ball_icon_texture, dest_rect, false)
			else:
				_draw_question_placeholder(radius, glow_col)

			# Elegant glow outline on reveal
			draw_arc(Vector2.ZERO, radius - 2.5, 0.0, TAU, 96, glow_col, 2.5, true)

		if rotation_angle != 0.0:
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		
	else:
		# Generic ball mode (without logo icon)
		draw_circle(Vector2.ZERO, radius - 2.5, Color(0.07, 0.07, 0.09))
		draw_arc(Vector2.ZERO, radius - 3.5, 0.0, TAU, 96, glow_col, 3.0, true)
		draw_arc(Vector2.ZERO, radius - 3.5, 0.0, TAU, 96, Color(glow_col.r, glow_col.g, glow_col.b, 0.35), 6.5, true)
		
		# Saturated core dot
		draw_circle(Vector2.ZERO, radius * 0.22, Color.WHITE)
		draw_circle(Vector2.ZERO, radius * 0.22, Color(glow_col.r, glow_col.g, glow_col.b, 0.5))

func _draw_question_placeholder(radius: float, glow_color: Color) -> void:
	var font = load("res://assets/fonts/Montserrat-ExtraBold.ttf") as Font
	if not font:
		font = ThemeDB.fallback_font
	if font:
		var font_size = int(radius * 1.3)
		var text = "?"
		var ascent = font.get_ascent(font_size)
		var descent = font.get_descent(font_size)
		var pos = Vector2(-radius, (ascent - descent) * 0.5)
		
		var shadow_col = Color(quiz_text_color.r, quiz_text_color.g, quiz_text_color.b, 0.4)
		draw_string(font, pos + Vector2(2, 2), text, HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0, font_size, shadow_col)
		draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0, font_size, quiz_text_color)

func _draw_quiz_question(radius: float, glow_color: Color) -> void:
	var font = load("res://assets/fonts/Montserrat-ExtraBold.ttf") as Font
	if not font:
		font = ThemeDB.fallback_font
	if font:
		var font_size = int(radius * 1.1)
		var text = "?"
		var ascent = font.get_ascent(font_size)
		var descent = font.get_descent(font_size)
		var pos = Vector2(-radius, (ascent - descent) * 0.5)
		
		var shadow_col = Color(quiz_text_color.r, quiz_text_color.g, quiz_text_color.b, 0.4)
		draw_string(font, pos + Vector2(1.5, 1.5), text, HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0, font_size, shadow_col)
		draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0, font_size, quiz_text_color)
