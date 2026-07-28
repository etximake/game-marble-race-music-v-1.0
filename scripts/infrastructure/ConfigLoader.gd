# ConfigLoader.gd
class_name ConfigLoader
extends RefCounted

static func load_config(file_path: String, template_path: String = "") -> Dictionary:
	# 1. Load Job Config (contains song data: audio notes, duration, etc.)
	if not FileAccess.file_exists(file_path):
		return {"error": "ConfigFileNotFound", "message": "Cannot find video_config.json at: " + file_path}
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return {"error": "InvalidConfigJson", "message": "Failed to open config file."}
	var content = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(content)
	if error != OK:
		return {"error": "InvalidConfigJson", "message": "JSON Parse Error: " + json.get_error_message() + " at line " + str(json.get_error_line())}
	
	var job_data = json.get_data()
	if typeof(job_data) != TYPE_DICTIONARY:
		return {"error": "InvalidConfigJson", "message": "Config must be a JSON object."}
		
	# 2. Load the gameplay snapshot belonging to this job.
	if template_path == "":
		template_path = file_path.get_base_dir() + "/gameplay_config.json"
	if not FileAccess.file_exists(template_path):
		return {"error": "ConfigFileNotFound", "message": "Cannot find gameplay_config.json at: " + template_path}
		
	var temp_file = FileAccess.open(template_path, FileAccess.READ)
	if not temp_file:
		return {"error": "InvalidConfigJson", "message": "Failed to open template config file."}
	var temp_content = temp_file.get_as_text()
	temp_file.close()
	
	var temp_json = JSON.new()
	var temp_error = temp_json.parse(temp_content)
	if temp_error != OK:
		return {"error": "InvalidConfigJson", "message": "Template JSON Parse Error: " + temp_json.get_error_message() + " at line " + str(temp_json.get_error_line())}
		
	var template_data = temp_json.get_data()
	if typeof(template_data) != TYPE_DICTIONARY:
		return {"error": "InvalidConfigJson", "message": "Template Config must be a JSON object."}
		
	# Job data must not override gameplay-owned configuration.
	for forbidden_field in ["game_mode", "gameplay", "visual", "phases"]:
		if job_data.has(forbidden_field):
			return {"error": "InvalidJobConfig", "message": "Job config must not contain template-owned field: " + forbidden_field}

	# 3. Merge Job Config into a copy of Template Config
	var merged_data = template_data.duplicate(true)
	_deep_merge(merged_data, job_data)
	
	# Job-specific assets are applied after the template merge.
	var job_assets = job_data.get("job_assets", {})
	if typeof(job_assets) == TYPE_DICTIONARY:
		var icon_path = str(job_assets.get("ball_icon_path", ""))
		if icon_path != "":
			merged_data["visual"]["ball_icon_path"] = icon_path
		var ball_color = str(job_assets.get("ball_color", ""))
		if ball_color != "":
			merged_data["visual"]["ball_color"] = ball_color

	# 4. Build runtime phase times from the template timeline policy and job duration.
	if merged_data.has("phases") and typeof(merged_data["phases"]) == TYPE_ARRAY:
		var phases = merged_data["phases"] as Array
		if not phases.is_empty():
			var duration = float(merged_data.get("video", {}).get("duration", 46.0))
			
			# Determine reveal time based on quiz reveal ratio, but guarantee at least 6 seconds of climax_storm
			var reveal_time = duration - 7.0
			if reveal_time < duration * 0.70:
				reveal_time = duration * 0.70 # fallback to 30% climax time for extremely short videos
				
			if merged_data.has("quiz") and typeof(merged_data["quiz"]) == TYPE_DICTIONARY:
				var quiz = merged_data["quiz"] as Dictionary
				quiz["reveal_time"] = reveal_time

			# Re-build phase list to strictly enforce fixed/clamped timings for Shorts pacing:
			# Phase 0: Intro - 2.0s (or 25% of duration if duration is very short)
			# Phase 1: Build-up - from 2.0s to 10.0s (or 25%-50% if duration is very short)
			# Phase 2: Final Storm - from 10.0s to reveal_time
			# Phase 3: Climax Storm - from reveal_time to duration
			var intro_end = 2.0
			var buildup_end = 10.0
			if duration < 12.0:
				intro_end = duration * 0.2
				buildup_end = duration * 0.5

			# Clear existing template phases and dynamically construct our 4-phase sequence
			var new_phases = []
			
			# Phase 1: intro
			new_phases.append({
				"name": "intro",
				"start_time": 0.0,
				"end_time": intro_end,
				"speed_multiplier": 1.0,
				"growth_multiplier": 1.0,
				"trail_multiplier": 1.5,
				"trajectory_control": 0.0
			})

			# Phase 2: build_up
			new_phases.append({
				"name": "build_up",
				"start_time": intro_end,
				"end_time": buildup_end,
				"speed_multiplier": 2.0,
				"growth_multiplier": 2.0,
				"trail_multiplier": 2.0,
				"trajectory_control": 0.5
			})

			# Phase 3: final_storm
			new_phases.append({
				"name": "final_storm",
				"start_time": buildup_end,
				"end_time": reveal_time,
				"speed_multiplier": 3.5,
				"growth_multiplier": 4.0,
				"trail_multiplier": 3.0,
				"trajectory_control": 1.0
			})

			# Phase 4: climax_storm (Storm unleashed on reveal, ball flies free and ultra fast)
			new_phases.append({
				"name": "climax_storm",
				"start_time": reveal_time,
				"end_time": duration,
				"speed_multiplier": 10.0,
				"growth_multiplier": 10.0,
				"trail_multiplier": 3.5,
				"trajectory_control": 1.0
			})

			merged_data["phases"] = new_phases
	
	# 5. Validate required top-level fields on the merged config
	var required_fields = ["game_mode", "video", "audio", "gameplay", "visual", "text", "quiz", "timeline", "phases"]
	for field in required_fields:
		if not merged_data.has(field):
			return {"error": "MissingRequiredConfigField", "message": "Missing required field: " + field}
	
	# Validate video values
	var video = merged_data.get("video")
	if typeof(video) != TYPE_DICTIONARY:
		return {"error": "InvalidConfigValue", "message": "video section must be an object."}
	if not video.has("width") or not video.has("height") or not video.has("duration") or not video.has("fps"):
		return {"error": "MissingRequiredConfigField", "message": "Missing width, height, duration, or fps in video"}
	if float(video.get("duration", 0.0)) <= 0:
		return {"error": "InvalidConfigValue", "message": "duration must be greater than 0"}
	if int(video.get("fps", 0)) <= 0:
		return {"error": "InvalidConfigValue", "message": "fps must be greater than 0"}
	if not GameModeRegistry.is_supported(str(merged_data.get("game_mode", ""))):
		return {"error": "UnsupportedGameMode", "message": "Unsupported game mode: " + str(merged_data.get("game_mode", ""))}

	var notes = merged_data.get("audio", {}).get("notes", [])
	if typeof(notes) != TYPE_ARRAY or notes.is_empty():
		return {"error": "InvalidAudioConfig", "message": "audio.notes must contain at least one note."}
	for i in range(notes.size()):
		var note = notes[i]
		if typeof(note) != TYPE_DICTIONARY or int(note.get("index", -1)) != i or str(note.get("file", "")) == "":
			return {"error": "InvalidAudioConfig", "message": "audio.notes must have contiguous indexes and file names."}
		var note_path = PathResolver.resolve_note_path(file_path.get_base_dir(), str(merged_data.get("audio", {}).get("note_clips_dir", "note_clips/")), str(note.get("file", "")))
		if not FileAccess.file_exists(note_path):
			return {"error": "AudioClipMissing", "message": "Cannot find note clip: " + note_path}

	var phases_to_validate = merged_data.get("phases", [])
	if typeof(phases_to_validate) != TYPE_ARRAY or phases_to_validate.is_empty():
		return {"error": "InvalidPhaseConfig", "message": "At least one gameplay phase is required."}
	var previous_end = 0.0
	for i in range(phases_to_validate.size()):
		var phase = phases_to_validate[i]
		if typeof(phase) != TYPE_DICTIONARY:
			return {"error": "InvalidPhaseConfig", "message": "Every phase must be an object."}
		var phase_start = float(phase.get("start_time", -1.0))
		var phase_end = float(phase.get("end_time", -1.0))
		if phase_start < 0.0 or phase_end <= phase_start or (i > 0 and absf(phase_start - previous_end) > 0.001):
			return {"error": "InvalidPhaseConfig", "message": "Gameplay phases must be contiguous and increasing."}
		previous_end = phase_end
	if absf(previous_end - float(video.get("duration", 0.0))) > 0.001:
		return {"error": "InvalidPhaseConfig", "message": "The last phase must end at video.duration."}
	
	return {"success": true, "data": merged_data}

static func _deep_merge(target: Dictionary, source: Dictionary):
	for key in source:
		if source[key] is Dictionary and target.has(key) and target[key] is Dictionary:
			_deep_merge(target[key], source[key])
		else:
			target[key] = source[key]
