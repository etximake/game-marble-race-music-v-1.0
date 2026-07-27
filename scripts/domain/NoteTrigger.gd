# NoteTrigger.gd
class_name NoteTrigger
extends RefCounted

var time: float
var source_event_type: String
var payload: RefCounted # E.g. CollisionInfo

func _init(p_time: float, p_source_event_type: String, p_payload: RefCounted = null):
	time = p_time
	source_event_type = p_source_event_type
	payload = p_payload
