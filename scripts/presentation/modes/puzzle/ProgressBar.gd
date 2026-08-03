# PuzzleProgressBar.gd
class_name PuzzleProgressBar
extends Node2D

var fill_ratio: float = 0.0
var played: int = 0
var total: int = 1
var bar_width: int = 900
var bar_height: int = 30
var time_elapsed: float = 0.0
var visible_self: bool = true

func setup():
	position = Vector2(90, 1620)

func update_progress(p_played: int, p_total: int):
	played = p_played
	total = max(p_total, 1)
	fill_ratio = clampf(float(played) / float(total), 0.0, 1.0)

func _process(delta):
	time_elapsed += delta
	queue_redraw()

func _draw():
	var bg_rect = Rect2(0, 0, bar_width, bar_height)
	draw_rect(bg_rect, Color(0.15, 0.15, 0.18, 0.95), true)

	var fill_width = bar_width * fill_ratio
	var hue = wrapf(time_elapsed * 0.25, 0.0, 1.0)
	var fill_col = Color.from_hsv(hue, 0.9, 0.85, 0.9)
	var fill_rect = Rect2(0, 0, fill_width, bar_height)
	draw_rect(fill_rect, fill_col, true)

	var glow_col = Color.from_hsv(hue, 0.9, 1.0, 0.4)
	draw_rect(bg_rect, glow_col, false, 2.0)
