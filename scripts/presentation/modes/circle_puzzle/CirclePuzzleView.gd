# CirclePuzzleView.gd
class_name CirclePuzzleView
extends Node2D

@onready var arena_view: ArenaView = $Arena
@onready var ball_view: BallView = $Ball
@onready var trail_renderer: TrailRenderer = $TrailRenderer
@onready var puzzle_grid: PuzzleGridOverlay = $PuzzleGrid
@onready var progress_bar: PuzzleProgressBar = $ProgressBar

var controller: RefCounted
var visual_config: Dictionary = {}
var note_count: int = 0
var quiz_config: Dictionary = {}
var phases: Array = []
var duration: float = 30.0
var puzzle_duration: float = 20.0
var countdown_started: bool = false

func setup(p_controller, p_visual_config, job_folder = "", phases = [], p_quiz_config = {}):
	controller = p_controller
	visual_config = p_visual_config
	quiz_config = p_quiz_config.duplicate(true)
	quiz_config["enabled"] = false
	self.phases = phases
	duration = 30.0
	if not self.phases.is_empty():
		duration = float(self.phases[-1].get("end_time", 30.0))

	puzzle_duration = float(quiz_config.get("reveal_time", duration - 6.0))
	if puzzle_duration < duration * 0.70:
		puzzle_duration = duration * 0.70

	arena_view.suppress_climax_fade = true
	arena_view.setup(controller.state.arena, visual_config, controller, phases)
	arena_view.set_ball_reference(ball_view)
	ball_view.is_time_synced_externally = true
	ball_view.setup(controller.state.ball, visual_config, job_folder, phases, p_quiz_config)
	trail_renderer.setup(controller, ball_view, visual_config, phases)

	var ball_icon_path = visual_config.get("ball_icon_path", "")
	var top_text = p_quiz_config.get("prompt", "")
	puzzle_grid.setup(ball_icon_path, top_text, job_folder, puzzle_duration, duration)

	trail_renderer.z_index = 1
	puzzle_grid.z_index = 2
	ball_view.z_index = 5

	progress_bar.setup()
	countdown_started = false

func _process(delta):
	if controller and ball_view:
		ball_view.time_elapsed = controller.current_time
		puzzle_grid.current_time = controller.current_time

		if progress_bar:
			progress_bar.fill_ratio = clampf(controller.current_time / puzzle_duration, 0.0, 1.0)

		if controller.current_time >= puzzle_duration:
			if puzzle_grid and not puzzle_grid.is_complete:
				puzzle_grid.reveal_all()

func handle_mode_event(event):
	if event.type == "ball_collided":
		var info = event.payload as CollisionInfo
		if info:
			trail_renderer.handle_collision(info)

			var ring_color = Color.from_string(visual_config.get("ball_color", "#00ffcc"), Color.WHITE)
			if visual_config.get("use_rainbow_trail", true):
				var hue = wrapf(float(info.hit_count) * 0.02, 0.0, 1.0)
				ring_color = Color.from_hsv(hue, 0.9, 0.9)

			var current_phase_name = info.phase_name
			if current_phase_name == "" and controller:
				var current_phase = PhaseRules.get_current_phase(controller.current_time, [])
				current_phase_name = current_phase.get("name", "")

			arena_view.flash_at(info.position, ring_color, info.normal, current_phase_name)
			ball_view.trigger_pulse(current_phase_name)

			if puzzle_grid:
				if controller.current_time >= puzzle_duration:
					puzzle_grid.reveal_all()
				elif controller.current_time >= 3.0:
					var angle = (info.position - puzzle_grid.center_offset).angle()
					puzzle_grid.flash_slice_at_angle(angle, controller.current_time, phases, ring_color)

	elif event.type == "note_triggered":
		note_count += 1
		if puzzle_grid:
			if controller.current_time >= puzzle_duration:
				puzzle_grid.reveal_all()

			if progress_bar:
				progress_bar.trigger_pulse()

func trigger_climax_effects():
	if puzzle_grid:
		puzzle_grid.reveal_all_with_animation()
	if arena_view:
		var ring_color = Color.from_string(visual_config.get("ball_color", "#00ffcc"), Color.WHITE)
		arena_view.flash_at(puzzle_grid.center_offset, ring_color, Vector2.UP, "climax_storm")
		arena_view.flash_at(puzzle_grid.center_offset, ring_color, Vector2.DOWN, "climax_storm")