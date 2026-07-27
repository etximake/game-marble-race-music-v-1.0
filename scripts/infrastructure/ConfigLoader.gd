# ConfigLoader.gd
class_name ConfigLoader
extends RefCounted

static func load_config(file_path: String, template_path: String = "res://shared/gameplay_template.json") -> Dictionary:
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
		
	# 2. Load Gameplay Template (contains ball, arena, visual, phases, etc.)
	if not FileAccess.file_exists(template_path):
		return {"error": "ConfigFileNotFound", "message": "Cannot find gameplay_template.json at: " + template_path}
		
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
		
	# 3. Merge Job Config into a copy of Template Config
	var merged_data = template_data.duplicate(true)
	_deep_merge(merged_data, job_data)
	
	# 4. Dynamically scale the last phase's end_time to match the song duration
	if merged_data.has("phases") and typeof(merged_data["phases"]) == TYPE_ARRAY:
		var phases = merged_data["phases"] as Array
		if not phases.is_empty():
			var last_phase = phases[-1]
			if typeof(last_phase) == TYPE_DICTIONARY:
				var duration = float(merged_data.get("video", {}).get("duration", 46.0))
				last_phase["end_time"] = duration
	
	# 5. Validate required top-level fields on the merged config
	var required_fields = ["project_version", "game_mode", "video", "audio", "gameplay", "visual", "text", "phases"]
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
	
	return {"success": true, "data": merged_data}

static func _deep_merge(target: Dictionary, source: Dictionary):
	for key in source:
		if source[key] is Dictionary and target.has(key) and target[key] is Dictionary:
			_deep_merge(target[key], source[key])
		else:
			target[key] = source[key]
