# PolygonBouncePhysics.gd
class_name PolygonBouncePhysics
extends RefCounted

const SMALL_MARGIN = 0.05

static func update_position(ball: BallState, delta: float):
	var dir = ball.velocity.normalized() if ball.velocity != Vector2.ZERO else Vector2.ZERO
	var gravity_effect = 1.0 + (dir.y * 0.175 if dir.y > 0.0 else dir.y * 0.15)
	ball.position += ball.velocity * gravity_effect * delta

static func closest_point_on_segment(p: Vector2, a: Vector2, b: Vector2) -> Vector2:
	var ab = b - a
	var ap = p - a
	var t = clampf(ap.dot(ab) / ab.length_squared(), 0.0, 1.0)
	return a + t * ab

static func check_polygon_collision(ball: BallState, arena: PolygonArenaState) -> Dictionary:
	var closest_dist = INF
	var closest_normal = Vector2.ZERO
	var closest_point = Vector2.ZERO
	var edge_index = -1

	var verts = arena.vertices
	var n = verts.size()
	for i in range(n):
		var a = verts[i]
		var b = verts[(i + 1) % n]
		var cp = closest_point_on_segment(ball.position, a, b)
		var dist = ball.position.distance_to(cp)

		if dist < closest_dist:
			closest_dist = dist
			closest_point = cp

			var edge = b - a
			var edge_normal = Vector2(-edge.y, edge.x).normalized()
			var to_ball = ball.position - cp
			if to_ball.dot(edge_normal) < 0.0:
				edge_normal = -edge_normal
			closest_normal = edge_normal.normalized()
			edge_index = i

	return {
		"collided": (closest_dist <= ball.radius),
		"normal": closest_normal,
		"closest_point": closest_point,
		"edge_index": edge_index,
		"penetration": ball.radius - closest_dist
	}

static func reflect_velocity(velocity: Vector2, normal: Vector2, current_time: float, duration: float, hit_count: int) -> Vector2:
	var reflected = velocity - 2.0 * velocity.dot(normal) * normal
	var to_center = -normal

	var angle_to_center = reflected.angle_to(to_center)
	var time_ratio = clampf(current_time / duration, 0.0, 1.0)

	if hit_count <= 2:
		var sign_factor = 1.0 if angle_to_center >= 0 else -1.0
		if abs(angle_to_center) < 0.2:
			sign_factor = 1.0 if randf() > 0.5 else -1.0
		var target_angle = (1.25 + deg_to_rad(5.0)) * sign_factor
		var rotation_needed = target_angle - angle_to_center
		reflected = reflected.rotated(rotation_needed)
	else:
		var decay_rate = lerpf(0.008, 0.08, time_ratio)
		reflected = reflected.rotated(angle_to_center * decay_rate)

		if decay_rate > 0.02:
			var precession_deg = 15.5
			reflected = reflected.rotated(deg_to_rad(precession_deg * (hit_count % 360)))

	var jitter = randf_range(-0.01, 0.01)
	return reflected.rotated(jitter)

static func resolve_inside_arena(ball: BallState, normal: Vector2, penetration: float):
	ball.position += normal * (penetration + SMALL_MARGIN)

static func apply_evolution(ball: BallState, gameplay_config: Dictionary, growth_mult: float, speed_mult: float):
	var ball_cfg = gameplay_config.get("ball", {})
	var arena_cfg = gameplay_config.get("arena", {})

	var growth_per_hit = float(ball_cfg.get("growth_per_hit", 1.0))
	var speed_growth_per_hit = float(ball_cfg.get("speed_growth_per_hit", 1.0))
	var max_radius = float(ball_cfg.get("max_radius", 320.0))
	var max_radius_ratio = float(ball_cfg.get("max_radius_ratio", 0.8))
	var max_speed = float(ball_cfg.get("max_speed", 1600.0))

	var arena_radius = float(arena_cfg.get("radius", 470.0))
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
