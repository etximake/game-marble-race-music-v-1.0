# CircleBounceView.gd
class_name CircleBounceView
extends Node2D

@onready var arena_view: ArenaView = $Arena
@onready var ball_view: BallView = $Ball
@onready var trail_renderer: TrailRenderer = $TrailRenderer

var controller: RefCounted
var visual_config: Dictionary = {}
var duration: float = 30.0
var progress_bar: Node2D = null

func setup(p_controller: RefCounted, p_visual_config: Dictionary, job_folder: String = "", phases: Array = [], quiz_config: Dictionary = {}):
	controller = p_controller
	visual_config = p_visual_config
	duration = 30.0
	if not phases.is_empty():
		duration = float(phases[-1].get("end_time", 30.0))

	arena_view.setup(controller.state.arena, visual_config, controller, phases)
	arena_view.set_ball_reference(ball_view)
	ball_view.is_time_synced_externally = true
	ball_view.setup(controller.state.ball, visual_config, job_folder, phases, quiz_config)
	trail_renderer.setup(controller, ball_view, visual_config, phases)

	if visual_config.get("show_progress_bar", false):
		var pb_script = load("res://scripts/presentation/modes/puzzle/ProgressBar.gd")
		if pb_script:
			progress_bar = Node2D.new()
			progress_bar.set_script(pb_script)
			add_child(progress_bar)
			progress_bar.setup()

func _process(delta: float):
	if controller and ball_view:
		ball_view.time_elapsed = controller.current_time
		if progress_bar:
			progress_bar.fill_ratio = clampf(controller.current_time / duration, 0.0, 1.0)

func handle_mode_event(event: GameEvent):
	if event.type == "ball_collided":
		var info = event.payload as CollisionInfo
		if info:
			trail_renderer.handle_collision(info)
 
			var ring_color = Color.from_string(visual_config.get("ball_color", "#00ffcc"), Color.WHITE)
			if visual_config.get("use_rainbow_trail", true):
				var hue = wrapf(float(info.hit_count) * 0.02, 0.0, 1.0)
				ring_color = Color.from_hsv(hue, 0.9, 0.9)
 
			var current_phase_name = info.phase_name if "phase_name" in info else ""
			if current_phase_name == "" and controller:
				var current_phase = PhaseRules.get_current_phase(controller.current_time, controller.config.get_phases() if "config" in controller else [])
				current_phase_name = current_phase.get("name", "")
 
			# Pass normal vector and phase name to create sparks and dynamic squish
			arena_view.flash_at(info.position, ring_color, info.normal, current_phase_name)
			ball_view.trigger_pulse(current_phase_name)

	elif event.type == "note_triggered" and progress_bar:
		progress_bar.trigger_pulse()
