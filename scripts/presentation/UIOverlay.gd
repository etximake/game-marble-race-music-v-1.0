# UIOverlay.gd
class_name UIOverlay
extends CanvasLayer

@onready var top_label: Label = $Control/TopLabel
@onready var bottom_label: Label = $Control/BottomLabel
@onready var countdown_label: Label = $Control/CountdownLabel

var is_showing_answer: bool = false
var blink_timer: float = 0.0

func setup(text_config: Dictionary):
	var show_text = text_config.get("show_text", true)
	visible = show_text
	is_showing_answer = false
	blink_timer = 0.0
	
	if show_text:
		top_label.text = text_config.get("top_text", "")
		bottom_label.text = text_config.get("bottom_text", "")
		
		# Reset any override from previous runs
		top_label.modulate.a = 1.0
		top_label.add_theme_font_size_override("font_size", 52)
		top_label.scale = Vector2.ONE
		bottom_label.visible = bottom_label.text != ""
		
		# Set custom fonts or sizes if needed, or stick to defaults
		top_label.visible = top_label.text != ""
		bottom_label.visible = bottom_label.text != ""
		
	if countdown_label:
		countdown_label.visible = false

func _process(delta: float):
	if is_showing_answer and top_label:
		blink_timer += delta * 6.0
		var alpha = 0.35 + 0.65 * absf(sin(blink_timer))
		top_label.modulate.a = alpha
		# Smoothly pulse scale
		var scale_val = 1.0 + 0.1 * absf(sin(blink_timer * 0.5))
		top_label.scale = Vector2(scale_val, scale_val)

func show_answer(song_name: String):
	if not top_label:
		return
	is_showing_answer = true
	blink_timer = 0.0
	var answer_text = song_name
	if answer_text == "":
		answer_text = "Cupid - Fifty Fifty" # Fallback if empty
	top_label.text = answer_text
	top_label.visible = true
	top_label.add_theme_font_size_override("font_size", 72)
	# Center pivot for scaling/rotation animation correctly
	top_label.pivot_offset = top_label.size / 2.0
	
	if bottom_label:
		bottom_label.visible = false # Hide helper text as answer is revealed

func update_countdown(current_time: float, reveal_time: float):
	if not countdown_label:
		return
		
	var time_left = reveal_time - current_time
	if time_left > 0.0 and time_left <= 3.0:
		countdown_label.visible = true
		
		# Calculate number (3, 2, or 1)
		var number = ceili(time_left)
		countdown_label.text = str(number)
		
		# Saturated neon colors for countdown to hype youngsters
		if number == 3:
			countdown_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2)) # Bright neon red
		elif number == 2:
			countdown_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.0)) # Vibrant orange
		else:
			countdown_label.add_theme_color_override("font_color", Color(0.1, 1.0, 0.1)) # Energetic neon green
			
		# Add a nice breathing pop/zoom effect using remaining fractional part of the second
		# fmod(time_left, 1.0) goes from 1.0 down to 0.0 in each second interval
		var progress = fmod(time_left, 1.0)
		if progress == 0.0:
			progress = 1.0
		# Start large, scale down slightly as the second progresses
		var scale_val = lerpf(1.0, 1.4, progress)
		countdown_label.scale = Vector2(scale_val, scale_val)
	else:
		countdown_label.visible = false
