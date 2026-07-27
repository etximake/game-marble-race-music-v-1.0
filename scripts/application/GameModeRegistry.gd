# GameModeRegistry.gd
class_name GameModeRegistry
extends RefCounted

const SUPPORTED_MODES = ["circle_bounce", "polygon_bounce"]

static func is_supported(mode_name: String) -> bool:
	return mode_name in SUPPORTED_MODES
