# GameEvent.gd
class_name GameEvent
extends RefCounted

var type: String
var time: float
var payload: RefCounted # Or Dictionary

func _init(p_type: String, p_time: float, p_payload: RefCounted = null):
	type = p_type
	time = p_time
	payload = p_payload
