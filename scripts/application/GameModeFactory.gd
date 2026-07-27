# GameModeFactory.gd
class_name GameModeFactory
extends RefCounted

static func create_controller(mode_name: String, gameplay_config: Dictionary) -> RefCounted:
	match mode_name:
		"circle_bounce":
			# CircleBounceModeController is instantiated here
			var script = load("res://scripts/application/modes/circle_bounce/CircleBounceModeController.gd")
			if script:
				var controller = script.new()
				controller.setup(gameplay_config)
				return controller
		"polygon_bounce":
			var script = load("res://scripts/application/modes/polygon_bounce/PolygonBounceModeController.gd")
			if script:
				var controller = script.new()
				controller.setup(gameplay_config)
				return controller
	return null

static func get_mode_view_path(mode_name: String) -> String:
	match mode_name:
		"circle_bounce":
			return "res://scenes/modes/circle_bounce/CircleBounceMode.tscn"
		"polygon_bounce":
			return "res://scenes/modes/polygon_bounce/PolygonBounceMode.tscn"
	return ""
