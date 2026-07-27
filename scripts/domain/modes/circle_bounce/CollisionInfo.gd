# CollisionInfo.gd
class_name CollisionInfo
extends RefCounted

var position: Vector2
var normal: Vector2
var hit_count: int
var time: float
var phase_name: String
var ball_radius: float
var ball_speed: float

func _init(pos: Vector2, norm: Vector2, hits: int, t: float, phase: String, radius: float, speed: float):
	position = pos
	normal = norm
	hit_count = hits
	time = t
	phase_name = phase
	ball_radius = radius
	ball_speed = speed
