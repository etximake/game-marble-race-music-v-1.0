# AudioPlaybackCoordinator.gd
class_name AudioPlaybackCoordinator
extends RefCounted

var session: AudioPlaybackSession
var sequence: NoteSequence
var repository: AudioAssetRepository
var note_player: AudioNotePlayer
var source_player: AudioSourcePlayer

var audio_delay_seconds: float = 0.0
var source_stream: AudioStream = null
var timeline_recorder: AudioTimelineRecorder = null

func setup(audio_config: Dictionary, job_folder: String, p_note_player: AudioNotePlayer, p_source_player: AudioSourcePlayer, reveal_time: float = -1.0) -> Dictionary:
	note_player = p_note_player
	source_player = p_source_player
	
	session = AudioPlaybackSession.new(audio_config)
	if reveal_time >= 0.0:
		session.set_reveal_time(reveal_time)
		
	audio_delay_seconds = float(audio_config.get("audio_delay_ms", 0.0)) / 1000.0
	
	var note_clips_dir = audio_config.get("note_clips_dir", "note_clips/")
	repository = AudioAssetRepository.new()
	repository.initialize(job_folder, note_clips_dir)
	
	var notes = audio_config.get("notes", [])
	sequence = NoteSequence.new(notes, session.loop_notes)
	
	# Preload note clips
	var preload_result = repository.preload_notes(notes)
	if not preload_result.get("success", false):
		var err_msg = "Failed to preload note clips: " + ", ".join(preload_result.get("errors", []))
		session.fail_session(err_msg)
		return {"success": false, "error": "AudioClipMissing", "message": err_msg}
		
	# Try preloading source audio if mode requires it
	if session.playback_mode in ["note_then_source", "source_only"]:
		var source_file = session.source_audio_file
		if source_file == "":
			# Fallback to default name if not in config
			source_file = "source_audio.wav"
			
		source_stream = repository.load_source_stream(source_file)
		if source_stream:
			print("Source stream preloaded successfully: ", source_file, " duration: ", source_stream.get_length())
		if not source_stream:
			var warning_msg = "Source audio not found for playback: " + source_file
			printerr(warning_msg)
			if session.playback_mode == "source_only":
				session.fail_session(warning_msg)
				return {"success": false, "error": "SourceAudioMissing", "message": warning_msg}
			else:
				# note_then_source can fall back to note_triggered if source is missing
				session.playback_mode = "note_triggered"
				session.start()
				print("Fallback to note_triggered mode due to missing source audio.")
				
	return {"success": true}

func set_timeline_recorder(p_timeline_recorder: AudioTimelineRecorder) -> void:
	timeline_recorder = p_timeline_recorder

func start_playback() -> void:
	if not session:
		return
	session.start()
	
	if session.playback_mode == "source_only" and source_stream and source_player:
		source_player.setup(source_stream)
		source_player.play_from(0.0)
	elif session.playback_mode == "note_triggered":
		# Trigger the initial note
		play_next_note(Time.get_ticks_msec())

func play_next_note(current_time_ms: float, sim_time: float = 0.0) -> void:
	if not session or not sequence or not note_player:
		return
		
	if not session.can_play_note(current_time_ms):
		return
		
	if not sequence.has_next_note():
		return
		
	var note = sequence.get_next_note()
	var note_file = note.get("file", "")
	if note_file == "":
		return
		
	var stream = repository.load_note_stream(note_file)
	if stream:
		session.record_note_played(current_time_ms)
		note_player.play_stream(stream, audio_delay_seconds)
		if timeline_recorder:
			timeline_recorder.record_note(note_file, sim_time)

func update_audio_filters(current_time: float, phases: Array) -> void:
	if not note_player or not session:
		return
		
	# Find current phase name and calculate filter cutoff
	var phase = PhaseRules.get_current_phase(current_time, phases)
	var phase_name = phase.get("name", "")
	
	if phase_name == "intro" or phase_name == "build_up":
		# Maintain muffled but clean sound (1500Hz: keeping details/tempo clear but avoiding high frequencies that make it too obvious)
		note_player.set_filter_cutoff(1500.0)
	elif phase_name == "final_storm":
		# Slowly open the filter to reveal the clear, satisfying neon audio climax
		# Interpolate cutoff_hz from 1500.0 Hz to 20000.0 Hz (fully open) during final_storm phase
		var start = float(phase.get("start_time", 0.0))
		var end = float(phase.get("end_time", 0.0))
		var phase_dur = end - start
		if phase_dur > 0.0:
			var t = clampf((current_time - start) / phase_dur, 0.0, 1.0)
			var cutoff = lerpf(1500.0, 20000.0, t)
			note_player.set_filter_cutoff(cutoff)
		else:
			note_player.set_filter_cutoff(20000.0)
	else:
		# fully open for climax_storm
		note_player.set_filter_cutoff(20000.0)

func handle_phase_changed(phase: Dictionary, current_time: float) -> void:
	if not session or not source_player:
		return
		
	var phase_name = phase.get("name", "")
	if phase_name == "climax_storm":
		if session.request_transition(current_time):
			var start_time = float(phase.get("start_time", 0.0))
			if source_stream:
				source_player.setup(source_stream)
				var success = source_player.play_from(start_time)
				if success:
					session.confirm_transition()
					note_player.stop_all()
					print("Audio transition to source audio completed successfully at: ", start_time)
					if timeline_recorder:
						var source_file = session.source_audio_file
						if source_file == "":
							source_file = "source_audio.wav"
						timeline_recorder.record_source(source_file, current_time, start_time)
				else:
					session.fail_transition("Source player failed to start stream")
					printerr("Audio transition failed: source player failed to start stream")
			else:
				session.fail_transition("Source stream is not loaded")
				printerr("Audio transition failed: source stream is not loaded")

func stop_all() -> void:
	if note_player:
		note_player.stop_all()
	if source_player:
		source_player.stop_source()
