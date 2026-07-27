# VideoConfig.gd
class_name VideoConfig
extends RefCounted

var raw_data: Dictionary = {}

func _init(data: Dictionary):
	raw_data = data

func get_project_version() -> String:
	return raw_data.get("project_version", "1.0")

func get_game_mode() -> String:
	return raw_data.get("game_mode", "")

func get_video_width() -> int:
	var video = raw_data.get("video", {})
	return int(video.get("width", 1080))

func get_video_height() -> int:
	var video = raw_data.get("video", {})
	return int(video.get("height", 1920))

func get_video_fps() -> int:
	var video = raw_data.get("video", {})
	return int(video.get("fps", 60))

func get_duration() -> float:
	var video = raw_data.get("video", {})
	return float(video.get("duration", 0.0))

func get_output_name() -> String:
	var video = raw_data.get("video", {})
	return video.get("output_name", "output")

func get_gameplay_config() -> Dictionary:
	return raw_data.get("gameplay", {})

func get_audio_config() -> Dictionary:
	return raw_data.get("audio", {})

func get_visual_config() -> Dictionary:
	return raw_data.get("visual", {})

func get_text_config() -> Dictionary:
	return raw_data.get("text", {})

func get_phases() -> Array:
	return raw_data.get("phases", [])

func get_current_phase(time: float) -> Dictionary:
	var phases = get_phases()
	for phase in phases:
		var start = float(phase.get("start_time", 0.0))
		var end = float(phase.get("end_time", 0.0))
		if time >= start and time <= end:
			return phase
	if phases.size() > 0:
		return phases[phases.size() - 1]
	return {}
