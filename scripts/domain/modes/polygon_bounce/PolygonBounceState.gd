# PolygonBounceState.gd
class_name PolygonBounceState
extends RefCounted

var ball: BallState
var arena: PolygonArenaState
var hit_count: int = 0

func _init(p_ball: BallState, p_arena: PolygonArenaState):
	ball = p_ball
	arena = p_arena
	hit_count = 0
