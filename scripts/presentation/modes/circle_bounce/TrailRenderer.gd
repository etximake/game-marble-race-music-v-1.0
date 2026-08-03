# TrailRenderer.gd
class_name TrailRenderer
extends Node2D

var visual_config: Dictionary = {}
var mode_controller: RefCounted
var ball_view: Node2D

var trail_mode: String = "web"
var trail_persistence: float = 1.0
var use_rainbow: bool = true
var use_glow: bool = true
var base_color: Color = Color.WHITE
var phases: Array = []

var stamps: Array[Dictionary] = []
var last_recorded_pos: Vector2 = Vector2.ZERO
var has_last_pos: bool = false
var elapsed_time: float = 0.0

func setup(controller: RefCounted, p_ball_view: Node2D, p_visual_config: Dictionary, p_phases: Array = []):
	mode_controller = controller
	ball_view = p_ball_view
	visual_config = p_visual_config

	trail_mode = visual_config.get("trail_mode", "web")
	trail_persistence = float(visual_config.get("trail_persistence", 1.0))
	use_rainbow = visual_config.get("use_rainbow_trail", true)
	use_glow = visual_config.get("use_glow", true)
	base_color = Color.from_string(visual_config.get("ball_color", "#00ffcc"), Color.WHITE)
	phases = p_phases
	z_index = 4

func handle_collision(_info):
	queue_redraw()

func _process(delta: float):
	if not mode_controller or not ball_view or not ball_view.state:
		return

	if "current_time" in mode_controller:
		elapsed_time = mode_controller.current_time
	else:
		elapsed_time += delta

	var ball = ball_view.state
	var current_pos = ball.position

	if not has_last_pos:
		last_recorded_pos = current_pos
		has_last_pos = true

	var dist = last_recorded_pos.distance_to(current_pos)
	var step = clampf(ball.radius * 0.28, 6.0, 22.0)

	if dist >= step:
		var steps_count = int(dist / step)
		for i in range(1, steps_count + 1):
			var t = float(i) / float(steps_count)
			var interp_pos = last_recorded_pos.lerp(current_pos, t)

			stamps.append({
				"position": interp_pos,
				"radius": ball.radius,
				"time": elapsed_time,
				"hit_count": mode_controller.state.hit_count if mode_controller and mode_controller.state else 0
			})

		last_recorded_pos = current_pos

		var trail_multiplier = 1.0
		if not phases.is_empty() and "current_time" in mode_controller:
			trail_multiplier = PhaseRules.get_trail_multiplier(elapsed_time, phases)
		var max_stamps = 20000
		if trail_mode == "short":
			max_stamps = int(200 * trail_persistence * trail_multiplier)
		elif trail_mode == "long":
			max_stamps = int(1200 * trail_persistence * trail_multiplier)
		else:
			max_stamps = int(5000 * trail_persistence * trail_multiplier)

		if stamps.size() > max_stamps:
			stamps = stamps.slice(stamps.size() - max_stamps)

	queue_redraw()

func _draw():
	if not mode_controller or not ball_view or not ball_view.state:
		return

	var stamps_count = stamps.size()
	if stamps_count == 0:
		return

	var trail_lifetime = 0.0
	if trail_mode == "short":
		trail_lifetime = 1.5
	elif trail_mode == "long":
		trail_lifetime = 5.0
	else:
		trail_lifetime = 12.0
	if not phases.is_empty():
		trail_lifetime *= PhaseRules.get_trail_multiplier(elapsed_time, phases)

	# Determine current phase name
	var current_phase = PhaseRules.get_current_phase(elapsed_time, phases)
	var current_phase_name = current_phase.get("name", "")

	for i in range(stamps_count):
		var stamp = stamps[i]
		var age = elapsed_time - stamp["time"]
		var age_factor = 1.0

		if trail_lifetime > 0.0:
			age_factor = clampf(1.0 - (age / trail_lifetime), 0.0, 1.0)

		if age_factor <= 0.01:
			continue

		var col = base_color
		if use_rainbow:
			var phase = float(i) / max(float(stamps_count), 1.0)
			var hue = wrapf(phase * 2.5 - elapsed_time * 0.35, 0.0, 1.0)
			col = Color.from_hsv(hue, 1.0, 1.0)

		col.a = age_factor * 1.0

		# Sharp black outline to create 3D layered/ribbed tube effect (Z-overlay overlapping)
		var outline_col = Color(0.0, 0.0, 0.0, age_factor * 1.0)
		draw_circle(stamp.position, stamp.radius, outline_col)
		draw_circle(stamp.position, stamp.radius - 2.5, col)
