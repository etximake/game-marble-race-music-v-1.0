# ArenaState.gd (polygon_bounce)
class_name PolygonArenaState
extends RefCounted

var type: String = "polygon"
var center: Vector2 = Vector2.ZERO
var radius: float = 0.0
var line_width: float = 0.0
var sides: int = 4
var rotation_offset: float = 0.0
var vertices: Array[Vector2] = []

func _init(p_type: String, p_center: Vector2, p_radius: float, p_line_width: float, p_sides: int = 4):
	type = p_type
	center = p_center
	radius = p_radius
	line_width = p_line_width
	sides = p_sides
	rotation_offset = 0.0
	vertices = []
	compute_vertices()

func compute_vertices():
	vertices.clear()
	var start_angle = rotation_offset - PI / 2.0
	for i in range(sides):
		var angle = start_angle + float(i) * TAU / float(sides)
		var vertex = center + Vector2(cos(angle), sin(angle)) * radius
		vertices.append(vertex)
