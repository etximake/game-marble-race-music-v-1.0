# AudioSourcePlayer.gd
class_name AudioSourcePlayer
extends AudioStreamPlayer

func setup(stream: AudioStream) -> void:
	self.stream = stream

func play_from(seconds: float) -> bool:
	if not stream:
		printerr("AudioSourcePlayer: Cannot play because stream is null")
		return false
	
	# Clamp play position to stream length
	var play_pos = seconds
	if play_pos < 0.0:
		play_pos = 0.0
	elif play_pos >= stream.get_length():
		printerr("AudioSourcePlayer: Play position is beyond stream length: ", seconds, " >= ", stream.get_length())
		return false
		
	play(play_pos)
	return playing

func stop_source() -> void:
	if playing:
		stop()
