# AudioPlaybackSession.gd
class_name AudioPlaybackSession
extends RefCounted

enum State {
	IDLE,
	PLAYING_NOTES,
	TRANSITIONING_TO_SOURCE,
	PLAYING_SOURCE,
	FAILED
}

var current_state: State = State.IDLE
var playback_mode: String = "note_triggered" # note_triggered, note_then_source, source_only
var min_note_interval_ms: float = 120.0
var last_play_time_ms: float = 0.0
var loop_notes: bool = true
var reveal_time: float = -1.0
var source_audio_file: String = ""
var is_transition_ready: bool = false
var error_message: String = ""

func _init(config: Dictionary):
	playback_mode = config.get("playback_mode", "note_then_source")
	# Support fallback to old note_mode if playback_mode is not present
	if not config.has("playback_mode") and config.get("note_mode") == "next_note_on_trigger":
		playback_mode = "note_then_source"
		
	min_note_interval_ms = float(config.get("min_note_interval_ms", 120.0))
	loop_notes = bool(config.get("loop_notes", true))
	source_audio_file = config.get("source_audio_file", "")
	
	current_state = State.IDLE

func start() -> void:
	if playback_mode == "source_only":
		current_state = State.PLAYING_SOURCE
	else:
		current_state = State.PLAYING_NOTES

func set_reveal_time(p_reveal_time: float) -> void:
	reveal_time = p_reveal_time

func can_play_note(current_time_ms: float) -> bool:
	if current_state != State.PLAYING_NOTES:
		return false
	if (current_time_ms - last_play_time_ms) < min_note_interval_ms:
		return false
	return true

func record_note_played(current_time_ms: float) -> void:
	last_play_time_ms = current_time_ms

func request_transition(current_time: float) -> bool:
	if playback_mode != "note_then_source":
		return false
	if current_state != State.PLAYING_NOTES:
		return false
	if reveal_time < 0.0 or current_time < reveal_time:
		return false
		
	current_state = State.TRANSITIONING_TO_SOURCE
	return true

func confirm_transition() -> void:
	if current_state == State.TRANSITIONING_TO_SOURCE:
		current_state = State.PLAYING_SOURCE

func fail_transition(reason: String) -> void:
	error_message = reason
	if current_state == State.TRANSITIONING_TO_SOURCE:
		current_state = State.PLAYING_NOTES # Fallback to notes

func fail_session(reason: String) -> void:
	error_message = reason
	current_state = State.FAILED
