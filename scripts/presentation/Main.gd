# Main.gd
extends Node

@onready var sim_controller: SimulationController = $SimulationController
@onready var audio_note_player: AudioNotePlayer = $AudioNotePlayer
@onready var ui_overlay: UIOverlay = $UIOverlay
@onready var error_overlay: ErrorOverlay = $ErrorOverlay

var config_path: String = "res://generated/jobs/job_002/video_config.json"
var template_path: String = ""
var selected_mode: String = "circle_bounce"
var job_folder: String = ""
var video_config: VideoConfig
var active_mode_view: Node2D
var active_mode_controller: RefCounted
var is_started: bool = false
var audio_source_player: AudioSourcePlayer
var audio_coordinator: AudioPlaybackCoordinator
var recording_coordinator: RecordingCoordinator
var record_requested: bool = false

func _ready():
	error_overlay.visible = false
	ui_overlay.visible = false
	
	recording_coordinator = RecordingCoordinator.new()
	
	# Parse command line arguments if run externally
	_parse_arguments()
	
	print("Main: DisplayServer name is: ", DisplayServer.get_name())
	
	_load_and_start()

func _unhandled_input(event: InputEvent):
	if not event is InputEventKey or not event.pressed or event.echo:
		return

	if event.keycode == KEY_R and not is_started:
		get_tree().reload_current_scene()
	elif event.keycode == KEY_SPACE and not is_started:
		_start_simulation(event.ctrl_pressed)

func _parse_arguments():
	# Allow passing --config, --template, --job_dir and --record from CLI
	var args = OS.get_cmdline_args()
	for i in range(args.size()):
		if args[i] == "--config" and i + 1 < args.size():
			config_path = args[i+1]
		elif args[i] == "--template" and i + 1 < args.size():
			template_path = args[i+1]
		elif args[i] == "--job_dir" and i + 1 < args.size():
			job_folder = args[i+1]
		elif args[i] == "--record":
			record_requested = true
			
	# Always derive the job folder from the config unless explicitly overridden.
	if job_folder == "":
		job_folder = config_path.get_base_dir()

func _load_and_start():
	if template_path == "":
		template_path = config_path.get_base_dir().path_join("gameplay_configs").path_join(selected_mode).path_join("gameplay_config.json")
		
	var load_result = ConfigLoader.load_config(config_path, template_path)
	if load_result.has("error"):
		error_overlay.show_error(load_result["error"], load_result["message"])
		return
		
	var data = load_result["data"]
	video_config = VideoConfig.new(data)
	
	var mode_name = video_config.get_game_mode()
	if not GameModeRegistry.is_supported(mode_name):
		error_overlay.show_error("UnsupportedGameMode", "The game mode '" + mode_name + "' is not supported.")
		return
		
	# Setup audio player and coordinator
	audio_source_player = AudioSourcePlayer.new()
	add_child(audio_source_player)
	
	audio_coordinator = AudioPlaybackCoordinator.new()
	var quiz_cfg = video_config.get_quiz_config()
	var reveal_time = float(quiz_cfg.get("reveal_time", -1.0))
	var audio_setup = audio_coordinator.setup(video_config.get_audio_config(), job_folder, audio_note_player, audio_source_player, reveal_time)
	if not audio_setup.get("success", false):
		error_overlay.show_error(audio_setup.get("error", "AudioSetupFailed"), audio_setup.get("message", ""))
		return
	
	# Setup UI Overlay
	ui_overlay.setup(video_config.get_text_config())
	var visual_config = video_config.get_visual_config().duplicate(true)
	var job_assets = video_config.get_job_assets()
	if job_assets.has("ball_icon_path"):
		visual_config["ball_icon_path"] = job_assets.get("ball_icon_path", "")
	if job_assets.has("ball_color") and str(job_assets.get("ball_color", "")) != "":
		visual_config["ball_color"] = job_assets.get("ball_color", "")
	
	# Instantiating active game mode view
	var view_path = GameModeFactory.get_mode_view_path(mode_name)
	var view_scene = load(view_path)
	if not view_scene:
		error_overlay.show_error("InvalidModeGameplay", "Failed to load mode scene: " + view_path)
		return
		
	active_mode_view = view_scene.instantiate()
	add_child(active_mode_view)
	# Move active mode view behind UI
	move_child(active_mode_view, get_node("UIOverlay").get_index())
	
	# Create game mode controller
	active_mode_controller = GameModeFactory.create_controller(mode_name, video_config.get_gameplay_config())
	if not active_mode_controller:
		error_overlay.show_error("InvalidModeGameplay", "Failed to create mode controller for: " + mode_name)
		return
		
	# Setup view
	if active_mode_view.has_method("setup"):
		active_mode_view.setup(active_mode_controller, visual_config, job_folder, video_config.get_phases(), video_config.get_quiz_config())
		
	# Setup background color
	var bg_color = Color.from_string(visual_config.get("background_color", "#050505"), Color.BLACK)
	RenderingServer.set_default_clear_color(bg_color)
	
	# Wire signals
	sim_controller.mode_event.connect(_on_mode_event)
	sim_controller.note_triggered.connect(_on_note_triggered)
	sim_controller.phase_changed.connect(_on_phase_changed)
	sim_controller.simulation_finished.connect(_on_simulation_finished)
	
	# Wait for Space before starting the simulation. No start prompt is shown in the render.
	if DisplayServer.get_name() == "headless" or record_requested:
		get_tree().create_timer(0.1).timeout.connect(
			func(): _start_simulation(record_requested)
		)

func _start_simulation(should_record: bool = false):
	if is_started or not video_config or not active_mode_controller:
		return

	is_started = true
	
	if should_record and recording_coordinator:
		recording_coordinator.start_recording(video_config, job_folder, get_window())
		if audio_coordinator:
			audio_coordinator.set_timeline_recorder(recording_coordinator.timeline_recorder)
			
	sim_controller.initialize(video_config, active_mode_controller, should_record)
	if audio_coordinator:
		audio_coordinator.start_playback()

func _process(delta: float):
	if is_started and ui_overlay and video_config and sim_controller:
		var quiz_cfg = video_config.get_quiz_config()
		var enabled = quiz_cfg.get("enabled", true)
		var reveal_t = float(quiz_cfg.get("reveal_time", -1.0))
		if enabled and reveal_t > 0.0:
			ui_overlay.update_countdown(sim_controller.current_time, reveal_t)
			
	if is_started and audio_coordinator and video_config and sim_controller:
		audio_coordinator.update_audio_filters(sim_controller.current_time, video_config.get_phases())
			
	if recording_coordinator and recording_coordinator.is_recording() and sim_controller:
		recording_coordinator.capture_frame(get_viewport(), sim_controller.current_time)

func _on_phase_changed(phase: Dictionary):
	var phase_name = phase.get("name", "")
	if phase_name == "climax_storm":
		var song_name = video_config.get_song_name()
		ui_overlay.show_answer(song_name)
	
	if audio_coordinator:
		audio_coordinator.handle_phase_changed(phase, sim_controller.current_time)

func _on_mode_event(event: GameEvent):
	if active_mode_view and active_mode_view.has_method("handle_mode_event"):
		active_mode_view.handle_mode_event(event)

func _on_note_triggered(trigger: NoteTrigger):
	if audio_coordinator:
		audio_coordinator.play_next_note(Time.get_ticks_msec(), trigger.time)

func _on_simulation_finished():
	print("Simulation finished successfully.")
	if recording_coordinator and recording_coordinator.is_recording():
		var repo = audio_coordinator.repository if audio_coordinator else null
		recording_coordinator.stop_recording(repo)
		
	if audio_coordinator:
		audio_coordinator.stop_all()
	get_tree().quit()
