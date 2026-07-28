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

# Interpolates a multiplier with a continuous evolution from phase start to phase end.
# This prevents static speed/growth plateaus during long phases and keeps visual pacing satisfying.
static func get_interpolated_value(time: float, phases: Array, key: String, default_val: float = 1.0) -> float:
	if phases.is_empty():
		return default_val
		
	# 1. Find where the current time falls relative to phases
	var first_start = float(phases[0].get("start_time", 0.0))
	if time <= first_start:
		return float(phases[0].get(key, default_val))
		
	var last_idx = phases.size() - 1
	var last_end = float(phases[last_idx].get("end_time", 0.0))
	if time >= last_end:
		return float(phases[last_idx].get(key, default_val))
		
	# 2. Continuous linear evolution from previous phase value to current phase value
	for i in range(phases.size()):
		var phase = phases[i]
		var start = float(phase.get("start_time", 0.0))
		var end = float(phase.get("end_time", 0.0))
		
		if time >= start and time <= end:
			var prev_val = default_val
			if i > 0:
				prev_val = float(phases[i-1].get(key, default_val))
			else:
				prev_val = float(phase.get(key, default_val))
				
			var target_val = float(phase.get(key, default_val))
			var phase_duration = end - start
			if phase_duration <= 0.0:
				return target_val
				
			# Linearly interpolate over the whole duration of the phase to ensure continuous speed growth
			var t = (time - start) / phase_duration
			return lerpf(prev_val, target_val, t)
			
	return default_val

static func get_speed_multiplier(time: float, phases: Array) -> float:
	return get_interpolated_value(time, phases, "speed_multiplier", 1.0)

static func get_growth_multiplier(time: float, phases: Array) -> float:
	return get_interpolated_value(time, phases, "growth_multiplier", 1.0)

static func get_trail_multiplier(time: float, phases: Array) -> float:
	return get_interpolated_value(time, phases, "trail_multiplier", 1.0)
