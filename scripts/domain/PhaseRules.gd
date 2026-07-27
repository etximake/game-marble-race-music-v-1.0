# PhaseRules.gd
class_name PhaseRules
extends RefCounted

static func get_current_phase(time: float, phases: Array) -> Dictionary:
	for phase in phases:
		var start = float(phase.get("start_time", 0.0))
		var end = float(phase.get("end_time", 0.0))
		if time >= start and time <= end:
			return phase
	if phases.size() > 0:
		return phases[phases.size() - 1]
	return {}

# Interpolates a multiplier with a short transition at phase boundaries.
# The previous implementation spread the transition across the whole phase,
# delaying the intended build-up burst until the phase was nearly over.
static func get_interpolated_value(time: float, phases: Array, key: String, default_val: float = 1.0) -> float:
	if phases.is_empty():
		return default_val
		
	# 1. Find where the current time falls relative to phases
	# Check if time is before the first phase
	var first_start = float(phases[0].get("start_time", 0.0))
	if time <= first_start:
		return float(phases[0].get(key, default_val))
		
	# Check if time is after the last phase
	var last_idx = phases.size() - 1
	var last_end = float(phases[last_idx].get("end_time", 0.0))
	if time >= last_end:
		return float(phases[last_idx].get(key, default_val))
		
	# 2. Transition quickly from the previous phase into the current phase.
	for i in range(phases.size()):
		var phase = phases[i]
		var start = float(phase.get("start_time", 0.0))
		var end = float(phase.get("end_time", 0.0))
		
		if time >= start and time <= end:
			var prev_val = default_val
			if i > 0:
				prev_val = float(phases[i-1].get(key, default_val))
			else:
				prev_val = float(phase.get(key, default_val)) # if first phase, start with its own value
				
			var target_val = float(phase.get(key, default_val))
			var transition_duration = minf(0.25, maxf((end - start) * 0.1, 0.01))
			if transition_duration <= 0.0:
				return target_val
				
			var t = clampf((time - start) / transition_duration, 0.0, 1.0)
			var smooth_t = t * t * (3.0 - 2.0 * t)
			return lerpf(prev_val, target_val, smooth_t)
			
	return default_val

static func get_speed_multiplier(time: float, phases: Array) -> float:
	return get_interpolated_value(time, phases, "speed_multiplier", 1.0)

static func get_growth_multiplier(time: float, phases: Array) -> float:
	return get_interpolated_value(time, phases, "growth_multiplier", 1.0)

static func get_trail_multiplier(time: float, phases: Array) -> float:
	return get_interpolated_value(time, phases, "trail_multiplier", 1.0)
