# PolygonArenaView.gd
class_name PolygonArenaView
extends Node2D

var state: PolygonArenaState
var ball_ref: Node2D
var color: Color = Color.WHITE
var use_glow: bool = true
var use_rainbow: bool = true
var time_elapsed: float = 0.0
var controller_ref: RefCounted = null
var phases: Array = []

var suppress_climax_fade: bool = false

var edge_flashes: Array[Dictionary] = []
var line_neon_pulses: Array[Dictionary] = []
var sparks: Array[Dictionary] = []
var shockwave_rings: Array[Dictionary] = []

func setup(p_state: PolygonArenaState, visual_config: Dictionary, p_controller: RefCounted = null, p_phases: Array = []):
	state = p_state
	color = Color.from_string(visual_config.get("ball_color", "#00ffcc"), Color.WHITE)
	use_glow = visual_config.get("use_glow", true)
	use_rainbow = visual_config.get("use_rainbow_trail", true)
	controller_ref = p_controller
	phases = p_phases
	z_index = 0
	queue_redraw()

func set_ball_reference(p_ball: Node2D):
	ball_ref = p_ball

func flash_at(flash_position: Vector2, flash_color: Color, normal: Vector2 = Vector2.ZERO, phase_name: String = ""):
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

	# Generate neon collision sparks
	if normal != Vector2.ZERO:
		var spark_count = 8
		var speed_min = 150.0
		var speed_max = 300.0
		var lifetime = 0.3
		
		# Pacing adjustments: sparks scale up as music progresses (intro: small/few, climax: big/lots)
		if phase_name == "intro":
			spark_count = 4
			speed_min = 100.0
			speed_max = 200.0
			lifetime = 0.2
		elif phase_name == "build_up":
			spark_count = 8
			speed_min = 180.0
			speed_max = 320.0
			lifetime = 0.3
		elif phase_name == "final_storm" or phase_name == "climax_storm":
			spark_count = 18
			speed_min = 300.0
			speed_max = 600.0
			lifetime = 0.45
			
		var bounce_dir = -normal # normal points outwards, so bounce points inwards
		for i in range(spark_count):
			# Add random angle deviation to sparks (+/- 45 degrees)
			var angle_dev = randf_range(-PI / 4.0, PI / 4.0)
			var spark_velocity = bounce_dir.rotated(angle_dev) * randf_range(speed_min, speed_max)
			sparks.append({
				"position": flash_position,
				"velocity": spark_velocity,
				"color": flash_color,
				"life": lifetime,
				"max_life": lifetime
			})

	# Spawn shockwave rings expanding outward from the polygon
	var ring_count = 4
	var ring_max_scale = 1.5
	if phase_name == "intro":
		ring_count = 3
		ring_max_scale = 1.3
	elif phase_name == "build_up":
		ring_count = 4
		ring_max_scale = 1.5
	elif phase_name == "final_storm" or phase_name == "climax_storm":
		ring_count = 5
		ring_max_scale = 1.8

	for r in range(ring_count):
		shockwave_rings.append({
			"delay": float(r) * 0.07,
			"life": 0.5,
			"max_life": 0.5,
			"scale": 1.0,
			"max_scale": ring_max_scale,
			"color": flash_color
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

	var k = sparks.size() - 1
	while k >= 0:
		var spark = sparks[k]
		spark["life"] -= delta
		if spark["life"] <= 0.0:
			sparks.remove_at(k)
		else:
			spark["position"] += spark["velocity"] * delta
			spark["velocity"] *= 0.95
		k -= 1

	var s = shockwave_rings.size() - 1
	while s >= 0:
		var ring = shockwave_rings[s]
		if ring["delay"] > 0.0:
			ring["delay"] -= delta
		else:
			ring["life"] -= delta
			if ring["life"] <= 0.0:
				shockwave_rings.remove_at(s)
			else:
				var progress = 1.0 - (ring["life"] / ring["max_life"])
				ring["scale"] = lerpf(1.0, ring["max_scale"], progress)
		s -= 1

	queue_redraw()

func _draw():
	if not state:
		return

	# Determine current phase name from the ball's controller reference if available
	var current_phase_name = ""
	var reveal_t = -1.0
	if controller_ref:
		var ctrl = controller_ref
		if "current_time" in ctrl and "gameplay_config" in ctrl:
			var current_phase = PhaseRules.get_current_phase(ctrl.current_time, phases)
			current_phase_name = current_phase.get("name", "")
			reveal_t = float(current_phase.get("start_time", -1.0)) if current_phase_name == "climax_storm" else -1.0

	var draw_col = color
	if use_rainbow:
		var hue = wrapf(time_elapsed * 0.05, 0.0, 1.0)
		draw_col = Color.from_hsv(hue, 0.85, 0.9)

	var glow_intensity = 1.0
	if ball_ref and ball_ref.get("state"):
		var ball_state = ball_ref.state
		if ball_state:
			var min_dist = _closest_edge_distance(ball_state.position)
			var proximity = clampf(1.0 - min_dist / (state.radius * 0.15), 0.0, 1.0)
			glow_intensity = 1.0 + proximity * 2.0

	var verts = state.vertices
	if verts.is_empty():
		return

	var closed_verts = verts.duplicate()
	closed_verts.append(verts[0])

	# Calculate arena line alpha (fade out completely during climax_storm)
	var arena_alpha = 1.0
	if current_phase_name == "climax_storm" and not suppress_climax_fade:
		var time_in_climax = 0.0
		if controller_ref:
			time_in_climax = controller_ref.current_time - reveal_t
		arena_alpha = clampf(1.0 - (time_in_climax / 0.6), 0.0, 1.0)
		
	if arena_alpha <= 0.001:
		return # Do not draw anything if fully faded out

	if use_glow:
		for i in range(8, 0, -1):
			var extra_width = float(i) * 2.5
			var alpha = 0.18 * (1.0 - (float(i) / 8.0)) * glow_intensity * arena_alpha
			draw_polyline(
				PackedVector2Array(closed_verts),
				Color(draw_col.r, draw_col.g, draw_col.b, alpha),
				state.line_width + extra_width,
				true
			)

	draw_polyline(PackedVector2Array(closed_verts), Color(draw_col.r, draw_col.g, draw_col.b, arena_alpha), state.line_width, true)

	for ring in shockwave_rings:
		var alpha = ring["life"] / ring["max_life"]
		if alpha <= 0.0 or ring["delay"] > 0.0:
			continue
		var col = ring["color"] as Color
		var ring_alpha = alpha * 0.55 * arena_alpha
		var scaled_verts = PackedVector2Array()
		for v in verts:
			scaled_verts.append(state.center + (v - state.center) * ring["scale"])
		var closed_scaled = scaled_verts.duplicate()
		closed_scaled.append(scaled_verts[0])
		draw_polyline(closed_scaled, Color(col.r, col.g, col.b, ring_alpha), state.line_width + 4.0 * alpha, true)

	for flash in edge_flashes:
		var alpha = flash["life"] / flash["max_life"]
		if alpha > 0.0:
			var col = flash["color"] as Color
			col.a = alpha * 0.9 * arena_alpha
			var flash_radius = lerpf(16.0, 4.0, 1.0 - alpha)
			draw_circle(flash["position"], flash_radius, col)

			var glow_col = Color(col.r, col.g, col.b, alpha * 0.3 * arena_alpha)
			draw_circle(flash["position"], flash_radius + 4.0, glow_col)

	# Draw sparks
	for spark in sparks:
		var alpha = spark["life"] / spark["max_life"]
		if alpha > 0.0:
			var col = spark["color"] as Color
			col.a = alpha * arena_alpha
			
			var vel = spark["velocity"] as Vector2
			var length = clampf(vel.length() * 0.08, 4.0, 32.0)
			var endpoint = spark["position"] - vel.normalized() * length
			
			# Glow line
			draw_line(spark["position"], endpoint, Color(col.r, col.g, col.b, alpha * 0.3 * arena_alpha), 6.0, true)
			# Core bright line
			draw_line(spark["position"], endpoint, Color(1.0, 1.0, 1.0, alpha * 0.9 * arena_alpha), 2.0, true)


	for pulse in line_neon_pulses:
		var alpha = pulse["life"] / pulse["max_life"]
		if alpha <= 0.0:
			continue

		var col = pulse["color"] as Color
		var pulse_smooth = sin(alpha * PI)

		for layer in range(6):
			var layer_alpha = (1.0 - float(layer) / 6.0) * pulse_smooth * arena_alpha
			var width = state.line_width + float(layer + 1) * 5.0 * pulse_smooth
			var neon_col = Color(col.r, col.g, col.b, layer_alpha * 0.5)
			draw_polyline(
				PackedVector2Array(closed_verts),
				neon_col,
				width,
				true
			)

		var core_alpha = pulse_smooth * pulse_smooth * arena_alpha
		var bright_col = Color(1.0, 1.0, 1.0, core_alpha * 0.8)
		draw_polyline(
			PackedVector2Array(closed_verts),
			bright_col,
			state.line_width + 2.0 * pulse_smooth,
			true
		)

func _closest_edge_distance(pos: Vector2) -> float:
	var verts = state.vertices
	if verts.is_empty():
		return INF

	var min_dist = INF
	var n = verts.size()
	for i in range(n):
		var cp = PolygonBouncePhysics.closest_point_on_segment(pos, verts[i], verts[(i + 1) % n])
		var d = pos.distance_to(cp)
		if d < min_dist:
			min_dist = d
	return min_dist
