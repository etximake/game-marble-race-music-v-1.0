# CircleBounceState.gd
class_name CircleBounceState
extends RefCounted

var ball: BallState
var arena: ArenaState
var hit_count: int = 0

func _init(p_ball: BallState, p_arena: ArenaState):
	ball = p_ball
	arena = p_arena
	hit_count = 0
