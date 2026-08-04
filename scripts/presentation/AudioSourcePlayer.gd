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
		# Nếu bị vượt quá do làm tròn float ở giây cuối, tự động lùi về vị trí an toàn sát cuối (0.05s trước khi kết thúc)
		play_pos = max(0.0, stream.get_length() - 0.05)
		
	play(play_pos)
	return playing

func stop_source() -> void:
	if playing:
		stop()
