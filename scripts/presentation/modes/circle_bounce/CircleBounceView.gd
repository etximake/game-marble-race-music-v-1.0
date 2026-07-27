# CircleBounceView.gd
class_name CircleBounceView
extends Node2D

@onready var arena_view: ArenaView = $Arena
@onready var ball_view: BallView = $Ball
@onready var trail_renderer: TrailRenderer = $TrailRenderer

var controller: RefCounted
var visual_config: Dictionary = {}

func setup(p_controller: RefCounted, p_visual_config: Dictionary, job_folder: String = "", phases: Array = [], quiz_config: Dictionary = {}):
	controller = p_controller
	visual_config = p_visual_config

	arena_view.setup(controller.state.arena, visual_config)
	arena_view.set_ball_reference(ball_view)
	ball_view.is_time_synced_externally = true
	ball_view.setup(controller.state.ball, visual_config, job_folder, phases, quiz_config)
	trail_renderer.setup(controller, ball_view, visual_config, phases)

func _process(delta: float):
	if controller and ball_view:
		ball_view.time_elapsed = controller.current_time

func handle_mode_event(event: GameEvent):
	if event.type == "ball_collided":
		var info = event.payload as CollisionInfo
		if info:
			trail_renderer.handle_collision(info)

			var ring_color = Color.from_string(visual_config.get("ball_color", "#00ffcc"), Color.WHITE)
			if visual_config.get("use_rainbow_trail", true):
				var hue = wrapf(float(info.hit_count) * 0.02, 0.0, 1.0)
				ring_color = Color.from_hsv(hue, 0.9, 0.9)

			arena_view.flash_at(info.position, ring_color)
			ball_view.trigger_pulse()
