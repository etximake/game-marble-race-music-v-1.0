# UIOverlay.gd
class_name UIOverlay
extends CanvasLayer

@onready var top_label: Label = $Control/TopLabel
@onready var bottom_label: Label = $Control/BottomLabel
@onready var countdown_label: Label = $Control/CountdownLabel

func setup(text_config: Dictionary):
	var show_text = text_config.get("show_text", true)
	visible = show_text
	
	if show_text:
		top_label.text = text_config.get("top_text", "")
		bottom_label.text = text_config.get("bottom_text", "")
		
		# Set custom fonts or sizes if needed, or stick to defaults
		top_label.visible = top_label.text != ""
		bottom_label.visible = bottom_label.text != ""
		
	if countdown_label:
		countdown_label.visible = false

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
