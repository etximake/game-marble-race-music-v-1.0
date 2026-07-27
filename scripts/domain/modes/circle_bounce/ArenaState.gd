# ArenaState.gd
class_name ArenaState
extends RefCounted

var type: String = "circle"
var center: Vector2 = Vector2.ZERO
var radius: float = 0.0
var line_width: float = 0.0

func _init(p_type: String, p_center: Vector2, p_radius: float, p_line_width: float):
	type = p_type
	center = p_center
	radius = p_radius
	line_width = p_line_width
