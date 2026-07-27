# UIOverlay.gd
class_name UIOverlay
extends CanvasLayer

@onready var top_label: Label = $Control/TopLabel
@onready var bottom_label: Label = $Control/BottomLabel

func setup(text_config: Dictionary):
	var show_text = text_config.get("show_text", true)
	visible = show_text
	
	if show_text:
		top_label.text = text_config.get("top_text", "")
		bottom_label.text = text_config.get("bottom_text", "")
		
		# Set custom fonts or sizes if needed, or stick to defaults
		top_label.visible = top_label.text != ""
		bottom_label.visible = bottom_label.text != ""
