# CirclePuzzleModeController.gd
class_name CirclePuzzleModeController
extends RefCounted

const COLLISION_COOLDOWN_MS = 20.0

var state: CirclePuzzleState
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
	var arena_type = arena_cfg.get("type", "circle")

	var ball = BallState.new(ball_pos, ball_vel, ball_radius)
	var arena = ArenaState.new(arena_type, arena_center, arena_radius, arena_line_width)
	state = CirclePuzzleState.new(ball, arena)
	cooldown_timer = 0.0

func update(delta: float, p_current_time: float, phase: Dictionary) -> Array:
	current_time = p_current_time
	return update_with_phases(delta, p_current_time, [], phase)

func update_with_phases(delta: float, p_current_time: float, phases: Array, phase: Dictionary) -> Array:
	current_time = p_current_time
	var events = []

	if cooldown_timer > 0.0:
		cooldown_timer -= delta * 1000.0

	CircleBouncePhysics.update_position(state.ball, delta)

	if CircleBouncePhysics.check_circle_collision(state.ball, state.arena):
		if cooldown_timer <= 0.0:
			state.hit_count += 1

			var growth_mult = 1.0
			var speed_mult = 1.0
			if not phases.is_empty():
				growth_mult = PhaseRules.get_growth_multiplier(current_time, phases)
				speed_mult = PhaseRules.get_speed_multiplier(current_time, phases)
			else:
				growth_mult = float(phase.get("growth_multiplier", 1.0))
				speed_mult = float(phase.get("speed_multiplier", 1.0))

			CircleBouncePhysics.apply_evolution(state.ball, gameplay_config, growth_mult, speed_mult)

			var normal = (state.ball.position - state.arena.center).normalized()
			var duration = 46.0
			if not phases.is_empty():
				duration = float(phases[-1].get("end_time", 46.0))
			var reflected_vel = CircleBouncePhysics.reflect_velocity(state.ball.velocity, normal, current_time, duration, state.hit_count)

			var cos_theta = abs(reflected_vel.normalized().dot(-normal))
			var ball_cfg = gameplay_config.get("ball", {})
			var min_comp = float(ball_cfg.get("tempo_compensation_min", 0.45))
			var compensation = clampf(cos_theta, min_comp, 1.0)
			state.ball.velocity = reflected_vel.normalized() * (state.ball.current_speed * compensation)

			CircleBouncePhysics.resolve_inside_arena(state.ball, state.arena, normal)

			cooldown_timer = COLLISION_COOLDOWN_MS

			var info = CollisionInfo.new(
				state.ball.position + normal * state.ball.radius,
				normal,
				state.hit_count,
				current_time,
				phase.get("name", ""),
				state.ball.radius,
				state.ball.current_speed
			)

			events.append(GameEvent.new("ball_collided", current_time, info))
			events.append(GameEvent.new("note_triggered", current_time, info))
		else:
			var normal = (state.ball.position - state.arena.center).normalized()
			CircleBouncePhysics.resolve_inside_arena(state.ball, state.arena, normal)

	return events
