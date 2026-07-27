# CircleBouncePhysics.gd
class_name CircleBouncePhysics
extends RefCounted

const SMALL_MARGIN = 0.05

static func update_position(ball: BallState, delta: float):
	var dir = ball.velocity.normalized() if ball.velocity != Vector2.ZERO else Vector2.ZERO
	# Gravity simulation: faster falling (dir.y > 0, +17.5%), slower rising (dir.y < 0, -15%)
	var gravity_effect = 1.0 + (dir.y * 0.175 if dir.y > 0.0 else dir.y * 0.15)
	ball.position += ball.velocity * gravity_effect * delta

static func check_circle_collision(ball: BallState, arena: ArenaState) -> bool:
	var dist = ball.position.distance_to(arena.center)
	return (dist + ball.radius) >= arena.radius

static func reflect_velocity(velocity: Vector2, normal: Vector2, current_time: float, duration: float, hit_count: int) -> Vector2:
	var reflected = velocity - 2.0 * velocity.dot(normal) * normal
	var to_center = -normal
	
	# Calculate current angle of incidence (angle between reflected and -normal)
	var angle_to_center = reflected.angle_to(to_center) # in radians, between -PI and PI
	var time_ratio = clampf(current_time / duration, 0.0, 1.0)
	
	# For the first few hits, we force a large grazing angle to create a polygon with many sides
	if hit_count <= 2:
		var sign_factor = 1.0 if angle_to_center >= 0 else -1.0
		if abs(angle_to_center) < 0.2:
			sign_factor = 1.0 if randf() > 0.5 else -1.0
		var target_angle = (1.25 + deg_to_rad(5.0)) * sign_factor
		var rotation_needed = target_angle - angle_to_center
		reflected = reflected.rotated(rotation_needed)
	else:
		# Decay the angle of incidence towards 0 (radial straight line)
		# Slow decay at the beginning, faster decay at the end of the song
		var decay_rate = lerpf(0.008, 0.08, time_ratio)
		reflected = reflected.rotated(angle_to_center * decay_rate)
		
		# Angular Precession: To prevent the ball from bouncing back and forth on the exact same diameter (horizontal line as in the image),
		# we apply a continuous rotational shift (precession) that spreads the lines evenly 360 degrees across the circle.
		# Note: We only apply this shift if the velocity is close to being radial, to avoid distorting the initial polygon phase.
		if decay_rate > 0.02:
			var precession_deg = 15.5
			# Rotate reflected vector based on hit count to rotate the diameter line 360 degrees
			reflected = reflected.rotated(deg_to_rad(precession_deg * (hit_count % 360)))
		
	# Add a tiny bit of random jitter so it doesn't look absolutely robotic
	var jitter = randf_range(-0.01, 0.01)
	return reflected.rotated(jitter)

static func resolve_inside_arena(ball: BallState, arena: ArenaState, normal: Vector2):
	ball.position = arena.center + normal * (arena.radius - ball.radius - SMALL_MARGIN)

static func apply_evolution(ball: BallState, gameplay_config: Dictionary, growth_mult: float, speed_mult: float):
	var ball_cfg = gameplay_config.get("ball", {})
	var arena_cfg = gameplay_config.get("arena", {})
	
	var growth_per_hit = float(ball_cfg.get("growth_per_hit", 1.0))
	var speed_growth_per_hit = float(ball_cfg.get("speed_growth_per_hit", 1.0))
	var max_radius = float(ball_cfg.get("max_radius", 320.0))
	var max_radius_ratio = float(ball_cfg.get("max_radius_ratio", 0.8))
	var max_speed = float(ball_cfg.get("max_speed", 1600.0))
	
	var arena_radius = float(arena_cfg.get("radius", 470.0))
	# Ensure the ball never takes up more than configured max_radius_ratio of the arena radius
	var absolute_max_radius = min(max_radius, arena_radius * max_radius_ratio)
	
	var effective_growth = 1.0 + (growth_per_hit - 1.0) * growth_mult
	var target_radius = ball.radius * effective_growth
	ball.radius = min(target_radius, absolute_max_radius)
	
	var current_speed = ball.current_speed
	var effective_speed_growth = 1.0 + (speed_growth_per_hit - 1.0) * speed_mult
	var target_speed = current_speed * effective_speed_growth
	ball.current_speed = min(target_speed, max_speed)
	
	if ball.velocity != Vector2.ZERO:
		ball.velocity = ball.velocity.normalized() * ball.current_speed
