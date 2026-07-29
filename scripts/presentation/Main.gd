# Main.gd
extends Node

@onready var sim_controller: SimulationController = $SimulationController
@onready var audio_note_player: AudioNotePlayer = $AudioNotePlayer
@onready var ui_overlay: UIOverlay = $UIOverlay
@onready var error_overlay: ErrorOverlay = $ErrorOverlay

var config_path: String = "res://generated/jobs/job_002/video_config.json"
var template_path: String = ""
var job_folder: String = ""
var video_config: VideoConfig
var active_mode_view: Node2D
var active_mode_controller: RefCounted
var is_started: bool = false

func _ready():
	error_overlay.visible = false
	ui_overlay.visible = false
	
	# Parse command line arguments if run externally
	_parse_arguments()
	
	_load_and_start()

func _unhandled_input(event: InputEvent):
	if not event is InputEventKey or not event.pressed or event.echo:
		return

	if event.keycode == KEY_R:
		get_tree().reload_current_scene()
	elif event.keycode == KEY_SPACE and not is_started:
		_start_simulation()

func _parse_arguments():
	# Allow passing --config, --template and --job_dir from CLI
	var args = OS.get_cmdline_args()
	for i in range(args.size()):
		if args[i] == "--config" and i + 1 < args.size():
			config_path = args[i+1]
		elif args[i] == "--template" and i + 1 < args.size():
			template_path = args[i+1]
		elif args[i] == "--job_dir" and i + 1 < args.size():
			job_folder = args[i+1]
			
	# Always derive the job folder from the config unless explicitly overridden.
	if job_folder == "":
		job_folder = config_path.get_base_dir()

func _load_and_start():
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
		
	# Setup audio player
	if not audio_note_player.setup(video_config.get_audio_config(), job_folder):
		error_overlay.show_error("AudioClipMissing", audio_note_player.setup_error)
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

func _start_simulation():
	if is_started or not video_config or not active_mode_controller:
		return

	is_started = true
	sim_controller.initialize(video_config, active_mode_controller)
	audio_note_player.start_source_audio_silent()
	# AudioNotePlayer will handle subsequent note playback from simulation events.
	audio_note_player.play_next_note()

func _process(delta: float):
	if is_started and ui_overlay and video_config and sim_controller:
		var quiz_cfg = video_config.get_quiz_config()
		var enabled = quiz_cfg.get("enabled", true)
		var reveal_t = float(quiz_cfg.get("reveal_time", -1.0))
		if enabled and reveal_t > 0.0:
			ui_overlay.update_countdown(sim_controller.current_time, reveal_t)

func _on_phase_changed(phase: Dictionary):
	var phase_name = phase.get("name", "")
	if phase_name == "climax_storm":
		var song_name = video_config.get_song_name()
		ui_overlay.show_answer(song_name)
		audio_note_player.reveal_source_audio(phase.get("start_time", 0.0))

func _on_mode_event(event: GameEvent):
	if active_mode_view and active_mode_view.has_method("handle_mode_event"):
		active_mode_view.handle_mode_event(event)

func _on_note_triggered(trigger: NoteTrigger):
	# AudioNotePlayer will handle the note playback
	audio_note_player.play_next_note()

func _on_simulation_finished():
	print("Simulation finished successfully.")
	get_tree().quit()
