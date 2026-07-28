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
		"color": Color.WHITE,
		"life": 0.25,
		"max_life": 0.25
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

	# Calculate current flash boost for the line
	var flash_boost = 0.0
	if not line_neon_pulses.is_empty():
		# Get the strongest active pulse
		for pulse in line_neon_pulses:
			var alpha = pulse["life"] / pulse["max_life"]
			var pulse_smooth = sin(alpha * PI)
			flash_boost = maxf(flash_boost, pulse_smooth * 0.3)

	# Main line color (keeps original behavior: can cycle rainbow color)
	var draw_col = color
	if use_rainbow:
		var hue = wrapf(time_elapsed * 0.05, 0.0, 1.0)
		draw_col = Color.from_hsv(hue, 0.85, 0.9)

	if state.type == "circle":
		# Soft semi-transparent white glow around the line
		if use_glow:
			for i in range(4, 0, -1):
				var extra_width = float(i) * 2.5
				# Extremely low alpha white glow that fades out, boosted slightly by collision
				var glow_alpha = 0.04 * (1.0 - (float(i) / 4.0)) + flash_boost * 0.06
				draw_arc(
					state.center,
					state.radius,
					0.0,
					TAU,
					360,
					Color(1.0, 1.0, 1.0, glow_alpha),
					state.line_width + extra_width,
					true
				)

		# Main arena boundary line (fully colored with slight collision flash boost)
		var main_line_col = Color(draw_col.r, draw_col.g, draw_col.b, 1.0)
		draw_arc(state.center, state.radius, 0.0, TAU, 360, main_line_col, state.line_width, true)

		# White core flash overlay during impact
		if flash_boost > 0.0:
			draw_arc(state.center, state.radius, 0.0, TAU, 360, Color(1.0, 1.0, 1.0, flash_boost), state.line_width - 1.0, true)

	# Local colorful impact glow burst at collision point (no solid sharp circle/dot)
	for flash in edge_flashes:
		var alpha = flash["life"] / flash["max_life"]
		if alpha > 0.0:
			var col = flash["color"] as Color
			
			# Soft inner glow burst
			var glow_col_1 = Color(col.r, col.g, col.b, alpha * 0.45)
			var radius_1 = lerpf(32.0, 8.0, 1.0 - alpha)
			draw_circle(flash["position"], radius_1, glow_col_1)

			# Soft outer halo glow
			var glow_col_2 = Color(col.r, col.g, col.b, alpha * 0.18)
			var radius_2 = radius_1 + 16.0
			draw_circle(flash["position"], radius_2, glow_col_2)
