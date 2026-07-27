# PathResolver.gd
class_name PathResolver
extends RefCounted

# job_folder could be e.g. "D:/HOANG HA/Tai lieu game godot/game-marble-race-music-v-1.0/generated/jobs/job_001/"
# or a relative path res://generated/jobs/job_001/
static func resolve_note_path(job_folder: String, note_clips_dir: String, note_file: String) -> String:
	# Ensure directory paths end with a slash if not empty
	var base_job = job_folder
	if base_job != "" and not base_job.ends_with("/") and not base_job.ends_with("\\"):
		base_job += "/"
	
	var clips_dir = note_clips_dir
	if clips_dir != "" and not clips_dir.ends_with("/") and not clips_dir.ends_with("\\"):
		clips_dir += "/"
	
	# If note_clips_dir is already absolute or relative to res:// or user://, use it directly
	var path = ""
	if clips_dir.begins_with("res://") or clips_dir.begins_with("user://") or clips_dir.contains(":/") or clips_dir.contains(":\\"):
		path = clips_dir + note_file
	else:
		path = base_job + clips_dir + note_file
	
	# Replace backslashes with slashes for Godot consistency
	path = path.replace("\\", "/")
	return path

static func resolve_path(job_folder: String, relative_or_absolute_path: String) -> String:
	if relative_or_absolute_path == "":
		return ""
	if relative_or_absolute_path.begins_with("res://") or relative_or_absolute_path.begins_with("user://") or relative_or_absolute_path.contains(":/") or relative_or_absolute_path.contains(":\\"):
		return relative_or_absolute_path.replace("\\", "/")
	
	var base_job = job_folder
	if base_job != "" and not base_job.ends_with("/") and not base_job.ends_with("\\"):
		base_job += "/"
	var path = base_job + relative_or_absolute_path
	return path.replace("\\", "/")
