# AudioNotePlayer.gd
class_name AudioNotePlayer
extends Node

const MIN_NOTE_INTERVAL_MS = 120.0

var sequence: NoteSequence
var job_folder: String = ""
var note_clips_dir: String = ""
var audio_delay_ms: float = 0.0

# Preloaded AudioStream resources mapped by filename to avoid repeated loading
var loaded_streams: Dictionary = {}
var players: Array[AudioStreamPlayer] = []
var last_play_time_ms: float = 0.0
var setup_error: String = ""

# Original full song playback fields
var source_audio_stream: AudioStream = null
var source_audio_player: AudioStreamPlayer = null
var is_playing_source_audio: bool = false

func _ready():
	# Create a pool of AudioStreamPlayers to support polyphony
	for i in range(16):
		var p = AudioStreamPlayer.new()
		add_child(p)
		players.append(p)
	
	source_audio_player = AudioStreamPlayer.new()
	add_child(source_audio_player)

func setup(audio_config: Dictionary, p_job_folder: String):
	job_folder = p_job_folder
	note_clips_dir = audio_config.get("note_clips_dir", "note_clips/")
	audio_delay_ms = float(audio_config.get("audio_delay_ms", 0.0))
	
	var loop_notes = audio_config.get("loop_notes", true)
	var notes = audio_config.get("notes", [])
	
	sequence = NoteSequence.new(notes, loop_notes)
	loaded_streams.clear()
	last_play_time_ms = 0.0
	setup_error = ""
	
	# Reset source audio states
	is_playing_source_audio = false
	if source_audio_player.playing:
		source_audio_player.stop()
	source_audio_stream = null
	
	# Pre-load note clips to prevent stuttering during simulation
	for note in notes:
		var note_file = note.get("file", "")
		if note_file != "" and not loaded_streams.has(note_file):
			var full_path = PathResolver.resolve_note_path(job_folder, note_clips_dir, note_file)
			var stream = NoteClipLoader.load_note_clip(full_path)
			if stream:
				loaded_streams[note_file] = stream
			else:
				setup_error = "Failed to load note clip: " + full_path
				printerr(setup_error)
	
	# Try preloading source full song audio
	var source_path = PathResolver.resolve_path(job_folder, "source_audio.wav")
	if FileAccess.file_exists(source_path):
		source_audio_stream = NoteClipLoader.load_note_clip(source_path)
		if source_audio_stream:
			source_audio_player.stream = source_audio_stream
			source_audio_player.volume_db = -80.0
	else:
		printerr("Source audio not found for playback at reveal: " + source_path)
		
	if setup_error != "":
			return false
	return true

func start_source_audio_silent():
	is_playing_source_audio = false
	if source_audio_player and source_audio_stream:
		source_audio_player.volume_db = -80.0
		source_audio_player.play(0.0)
		print("Started source audio silently at 0.0s")

func play_next_note():
	if is_playing_source_audio:
		return # Stop single notes trigger when playing full source audio
		
	if not sequence or not sequence.has_next_note():
		return
		
	var current_time_ms = Time.get_ticks_msec()
	if (current_time_ms - last_play_time_ms) < MIN_NOTE_INTERVAL_MS:
		# Audio spam prevention: skip playing this note if it's too close to the last one
		return
	
	last_play_time_ms = current_time_ms
	
	var note = sequence.get_next_note()
	var note_file = note.get("file", "")
	if note_file == "":
		return
		
	var stream = loaded_streams.get(note_file)
	if not stream:
		# Fallback to load on the fly if not preloaded
		var full_path = PathResolver.resolve_note_path(job_folder, note_clips_dir, note_file)
		stream = NoteClipLoader.load_note_clip(full_path)
		if stream:
			loaded_streams[note_file] = stream
			
	if stream:
		if audio_delay_ms > 0:
			await get_tree().create_timer(audio_delay_ms / 1000.0).timeout
		_play_stream(stream)

func reveal_source_audio(current_time: float):
	is_playing_source_audio = true
	
	# Mute/stop all notes currently playing
	for p in players:
		p.stop()
		
	if source_audio_stream and source_audio_player:
		source_audio_player.volume_db = 0.0 # Unmute
		print("Revealed source audio (unmuted) at game time: ", current_time)
		# Safety check: if for some reason the player stopped playing or drifted too much (e.g. > 0.5s), seek to sync
		if not source_audio_player.playing or absf(source_audio_player.get_playback_position() - current_time) > 0.5:
			source_audio_player.play(current_time)
			print("Syncing source audio player to position: ", current_time)
	else:
		printerr("Cannot play source audio: stream or player is null")

func _play_stream(stream: AudioStream):
	# Find an idle player
	for p in players:
		if not p.playing:
			p.stream = stream
			p.play()
			return
	
	# If all players are busy, steal the oldest one
	var oldest_player = players[0]
	oldest_player.stream = stream
	oldest_player.play()
