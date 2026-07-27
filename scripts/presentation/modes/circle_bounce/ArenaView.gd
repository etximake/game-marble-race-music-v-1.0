# ArenaView.gd
class_name ArenaView
extends Node2D

var state: ArenaState
var ball_ref: Node2D
var color: Color = Color.WHITE
var use_glow: bool = true
var use_rainbow: bool = true
var time_elapsed: float = 0.0

var edge_flashes: Array[Dictionary] = []
var line_neon_pulses: Array[Dictionary] = []

func setup(p_state: ArenaState, visual_config: Dictionary):
	state = p_state
	color = Color.from_string(visual_config.get("ball_color", "#00ffcc"), Color.WHITE)
	use_glow = visual_config.get("use_glow", true)
	use_rainbow = visual_config.get("use_rainbow_trail", true)
	queue_redraw()

func set_ball_reference(p_ball: Node2D):
	ball_ref = p_ball

func flash_at(flash_position: Vector2, flash_color: Color):
	edge_flashes.append({
		"position": flash_position,
		"color": flash_color,
		"life": 0.25,
		"max_life": 0.25
	})

	line_neon_pulses.append({
		"color": flash_color,
		"life": 0.35,
		"max_life": 0.35
	})

func _process(delta: float):
	if use_rainbow:
		time_elapsed += delta

	var i = edge_flashes.size() - 1
	while i >= 0:
		var flash = edge_flashes[i]
		flash["life"] -= delta
		if flash["life"] <= 0.0:
			edge_flashes.remove_at(i)
		i -= 1

	var j = line_neon_pulses.size() - 1
	while j >= 0:
		var pulse = line_neon_pulses[j]
		pulse["life"] -= delta
		if pulse["life"] <= 0.0:
			line_neon_pulses.remove_at(j)
		j -= 1

	queue_redraw()

func _draw():
	if not state:
		return

	var draw_col = color
	if use_rainbow:
		var hue = wrapf(time_elapsed * 0.05, 0.0, 1.0)
		draw_col = Color.from_hsv(hue, 0.85, 0.9)

	var glow_intensity = 1.0
	if ball_ref and ball_ref.get("state"):
		var ball_state = ball_ref.state
		if ball_state:
			var dist = ball_state.position.distance_to(state.center)
			var proximity = clampf(1.0 - (state.radius - dist) / (state.radius * 0.15), 0.0, 1.0)
			glow_intensity = 1.0 + proximity * 2.0

	if state.type == "circle":
		if use_glow:
			for i in range(8, 0, -1):
				var extra_width = float(i) * 2.5
				var alpha = 0.18 * (1.0 - (float(i) / 8.0)) * glow_intensity
				draw_arc(
					state.center,
					state.radius,
					0.0,
					TAU,
					360,
					Color(draw_col.r, draw_col.g, draw_col.b, alpha),
					state.line_width + extra_width,
					true
				)

		draw_arc(state.center, state.radius, 0.0, TAU, 360, draw_col, state.line_width, true)

	for flash in edge_flashes:
		var alpha = flash["life"] / flash["max_life"]
		if alpha > 0.0:
			var col = flash["color"] as Color
			col.a = alpha * 0.9
			var flash_radius = lerpf(16.0, 4.0, 1.0 - alpha)
			draw_circle(flash["position"], flash_radius, col)

			var glow_col = Color(col.r, col.g, col.b, alpha * 0.3)
			draw_circle(flash["position"], flash_radius + 4.0, glow_col)

	for pulse in line_neon_pulses:
		var alpha = pulse["life"] / pulse["max_life"]
		if alpha <= 0.0:
			continue

		var col = pulse["color"] as Color
		var pulse_smooth = sin(alpha * PI)

		for layer in range(6):
			var layer_alpha = (1.0 - float(layer) / 6.0) * pulse_smooth
			var width = state.line_width + float(layer + 1) * 5.0 * pulse_smooth
			var neon_col = Color(col.r, col.g, col.b, layer_alpha * 0.5)
			draw_arc(
				state.center,
				state.radius,
				0.0,
				TAU,
				360,
				neon_col,
				width,
				true
			)

		var core_alpha = pulse_smooth * pulse_smooth
		var bright_col = Color(1.0, 1.0, 1.0, core_alpha * 0.8)
		draw_arc(
			state.center,
			state.radius,
			0.0,
			TAU,
			360,
			bright_col,
			state.line_width + 2.0 * pulse_smooth,
			true
		)
