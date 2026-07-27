# NoteSequence.gd
class_name NoteSequence
extends RefCounted

var notes: Array = []
var loop_notes: bool = true
var current_note_index: int = 0
var exhausted: bool = false

func _init(p_notes: Array, p_loop_notes: bool):
	notes = p_notes
	loop_notes = p_loop_notes
	current_note_index = 0
	exhausted = notes.size() == 0

func get_next_note() -> Dictionary:
	if exhausted or notes.size() == 0:
		return {}
	
	var note = notes[current_note_index]
	current_note_index += 1
	
	if current_note_index >= notes.size():
		if loop_notes:
			current_note_index = 0
		else:
			exhausted = true
			
	return note

func reset():
	current_note_index = 0
	exhausted = notes.size() == 0

func has_next_note() -> bool:
	return not exhausted
