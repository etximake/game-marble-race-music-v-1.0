# PolygonPuzzleModeController.gd
class_name PolygonPuzzleModeController
extends RefCounted

const COLLISION_COOLDOWN_MS = 20.0

var state: PolygonPuzzleState
var gameplay_config: Dictionary = {}
var cooldown_timer: float = 0.0
var current_time: float = 0.0

func setup(config: Dictionary):
	gameplay_config = config
	var ball_cfg = config.get("ball", {})
	var arena_cfg = config.get("arena", {})

	var ball_pos = Vector2(
		float(ball_cfg.get("start_position", [540, 960])[0]),
		float(ball_cfg.get("start_position", [540, 960])[1])
	)
	var ball_vel = Vector2(
		float(ball_cfg.get("start_velocity", [420, -520])[0]),
		float(ball_cfg.get("start_velocity", [420, -520])[1])
	)
	var ball_radius = float(ball_cfg.get("start_radius", 24.0))

	var arena_center = Vector2(
		float(arena_cfg.get("center", [540, 960])[0]),
		float(arena_cfg.get("center", [540, 960])[1])
	)
	var arena_radius = float(arena_cfg.get("radius", 470.0))
	var arena_line_width = float(arena_cfg.get("line_width", 10.0))
	
	var sides_options = [4, 5, 6]
	var arena_sides = sides_options[randi() % sides_options.size()]
	var arena_type = "square"
	if arena_sides == 5:
		arena_type = "pentagon"
	elif arena_sides == 6:
		arena_type = "hexagon"

	var ball = BallState.new(ball_pos, ball_vel, ball_radius)
	var arena = PolygonArenaState.new(arena_type, arena_center, arena_radius, arena_line_width, arena_sides)
	state = PolygonPuzzleState.new(ball, arena)
	cooldown_timer = 0.0

func update(delta: float, p_current_time: float, phase: Dictionary) -> Array:
	current_time = p_current_time
	return update_with_phases(delta, p_current_time, [], phase)

func update_with_phases(delta: float, p_current_time: float, phases: Array, phase: Dictionary) -> Array:
	current_time = p_current_time
	var events = []

	if cooldown_timer > 0.0:
		cooldown_timer -= delta * 1000.0

	var phase_name = phase.get("name", "")

	PolygonBouncePhysics.update_position(state.ball, delta)

	var col_result = PolygonBouncePhysics.check_polygon_collision(state.ball, state.arena)
	if col_result["collided"]:
		if cooldown_timer <= 0.0:
			state.hit_count += 1

			var normal = col_result["normal"] as Vector2
			var penetration = col_result["penetration"] as float
			var closest_point = col_result["closest_point"] as Vector2

			var growth_mult = 1.0
			var speed_mult = 1.0
			if not phases.is_empty():
				growth_mult = PhaseRules.get_growth_multiplier(current_time, phases)
				speed_mult = PhaseRules.get_speed_multiplier(current_time, phases)
			else:
				growth_mult = float(phase.get("growth_multiplier", 1.0))
				speed_mult = float(phase.get("speed_multiplier", 1.0))

			PolygonBouncePhysics.apply_evolution(state.ball, gameplay_config, growth_mult, speed_mult)

			var duration = 46.0
			if not phases.is_empty():
				duration = float(phases[-1].get("end_time", 46.0))
			var reflected_vel = PolygonBouncePhysics.reflect_velocity(state.ball.velocity, normal, current_time, duration, state.hit_count)

			var cos_theta = abs(reflected_vel.normalized().dot(-normal))
			var ball_cfg = gameplay_config.get("ball", {})
			var min_comp = float(ball_cfg.get("tempo_compensation_min", 0.45))
			var compensation = clampf(cos_theta, min_comp, 1.0)
			state.ball.velocity = reflected_vel.normalized() * (state.ball.current_speed * compensation)

			PolygonBouncePhysics.resolve_inside_arena(state.ball, state.arena.center, penetration)

			cooldown_timer = COLLISION_COOLDOWN_MS

			var collision_pos = closest_point + normal * state.ball.radius
			var info = PolygonCollisionInfo.new(
				collision_pos,
				normal,
				state.hit_count,
				current_time,
				phase_name,
				state.ball.radius,
				state.ball.current_speed
			)

			var collide_event = GameEvent.new("ball_collided", current_time, info)
			var trigger_event = GameEvent.new("note_triggered", current_time, info)
			events.append(collide_event)
			events.append(trigger_event)
		else:
			var normal = col_result["normal"] as Vector2
			var penetration = col_result["penetration"] as float
			PolygonBouncePhysics.resolve_inside_arena(state.ball, state.arena.center, penetration)

	return events
