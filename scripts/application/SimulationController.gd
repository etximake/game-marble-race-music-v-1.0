# SimulationController.gd
class_name SimulationController
extends Node

signal mode_event(event: GameEvent)
signal note_triggered(note_trigger: NoteTrigger)
signal phase_changed(phase: Dictionary)
signal simulation_finished
signal simulation_error(error_code: String, message: String)

var config: VideoConfig
var current_time: float = 0.0
var active_mode_controller: RefCounted
var last_phase_name: String = ""
var is_running: bool = false
var force_fixed_delta: bool = false

func initialize(video_config: VideoConfig, controller: RefCounted, p_force_fixed_delta: bool = false):
	config = video_config
	active_mode_controller = controller
	current_time = 0.0
	last_phase_name = ""
	is_running = true
	force_fixed_delta = p_force_fixed_delta

func _process(delta: float):
	if not is_running:
		return
	
	# Constant delta matching fps configuration for offline render stability
	var sim_delta = delta
	if force_fixed_delta or ProjectSettings.get_setting("rendering/renderer/movie_writer/enabled", false) or Engine.is_editor_hint():
		sim_delta = 1.0 / float(config.get_video_fps())
	
	current_time += sim_delta
	
	# Check duration
	if current_time >= config.get_duration():
		is_running = false
		simulation_finished.emit()
		return
	
	# Phase update check
	var phases = config.get_phases()
	var phase = PhaseRules.get_current_phase(current_time, phases)
	var phase_name = phase.get("name", "")
	if phase_name != last_phase_name:
		last_phase_name = phase_name
		phase_changed.emit(phase)
	
	# Update mode controller
	if active_mode_controller:
		# Pass the phase array to allow smooth interpolation of multipliers inside update
		var events = []
		if active_mode_controller.has_method("update_with_phases"):
			events = active_mode_controller.update_with_phases(sim_delta, current_time, phases, phase)
		else:
			events = active_mode_controller.update(sim_delta, current_time, phase)
			
		for event in events:
			mode_event.emit(event)
			if event.type == "note_triggered":
				var trigger_payload = event.payload
				var trigger = NoteTrigger.new(current_time, event.type, trigger_payload)
				note_triggered.emit(trigger)
