# AudioAssetRepository.gd
class_name AudioAssetRepository
extends RefCounted

var job_folder: String = ""
var note_clips_dir: String = ""
var loaded_streams: Dictionary = {}

func initialize(p_job_folder: String, p_note_clips_dir: String) -> void:
	job_folder = p_job_folder
	note_clips_dir = p_note_clips_dir
	loaded_streams.clear()

func load_note_stream(note_file: String) -> AudioStream:
	if note_file == "":
		return null
	if loaded_streams.has(note_file):
		return loaded_streams[note_file]
		
	var full_path = PathResolver.resolve_note_path(job_folder, note_clips_dir, note_file)
	var stream = NoteClipLoader.load_note_clip(full_path)
	if stream:
		loaded_streams[note_file] = stream
	return stream

func load_source_stream(source_file: String) -> AudioStream:
	if source_file == "":
		return null
	var full_path = PathResolver.resolve_path(job_folder, source_file)
	if not FileAccess.file_exists(full_path):
		printerr("AudioAssetRepository: Source audio file not found at " + full_path)
		return null
	return NoteClipLoader.load_note_clip(full_path)

func preload_notes(notes: Array) -> Dictionary:
	var errors = []
	for note in notes:
		var note_file = note.get("file", "")
		if note_file != "" and not loaded_streams.has(note_file):
			var stream = load_note_stream(note_file)
			if not stream:
				errors.append("Failed to load note: " + note_file)
	
	if errors.size() > 0:
		return {"success": false, "errors": errors}
	return {"success": true}
