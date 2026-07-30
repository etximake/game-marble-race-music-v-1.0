# AudioTimelineRecorder.gd
class_name AudioTimelineRecorder
extends RefCounted

var events: Array = []
var duration: float = 0.0

func _init():
	events.clear()
	duration = 0.0

func record_note(note_file: String, current_time: float) -> void:
	events.append({
		"type": "note",
		"file": note_file,
		"time": current_time
	})

func record_source(source_file: String, current_time: float, start_position: float) -> void:
	events.append({
		"type": "source",
		"file": source_file,
		"time": current_time,
		"start_position": start_position
	})

func save_timeline(output_path: String) -> bool:
	var dir = output_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir):
		var err = DirAccess.make_dir_recursive_absolute(dir)
		if err != OK:
			printerr("AudioTimelineRecorder: Failed to create directories for: ", output_path)
			return false
			
	var file = FileAccess.open(output_path, FileAccess.WRITE)
	if not file:
		printerr("AudioTimelineRecorder: Failed to open timeline file for writing: ", output_path)
		return false
		
	var data = {
		"duration": duration,
		"events": events
	}
	
	file.store_string(JSON.stringify(data, "  "))
	file.close()
	return true
