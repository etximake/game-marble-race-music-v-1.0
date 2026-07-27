# ErrorOverlay.gd
class_name ErrorOverlay
extends CanvasLayer

@onready var error_title: Label = $Control/Panel/MarginContainer/VBoxContainer/ErrorTitle
@onready var error_message: Label = $Control/Panel/MarginContainer/VBoxContainer/ErrorMessage

func show_error(code: String, message: String):
	visible = true
	error_title.text = "CRITICAL ERROR: " + code
	error_message.text = message
	get_tree().paused = true
