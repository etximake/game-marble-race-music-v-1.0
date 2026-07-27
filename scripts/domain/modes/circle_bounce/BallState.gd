# BallState.gd
class_name BallState
extends RefCounted

var position: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO
var radius: float = 0.0
var current_speed: float = 0.0

func _init(pos: Vector2, vel: Vector2, rad: float):
	position = pos
	velocity = vel
	radius = rad
	current_speed = vel.length()
