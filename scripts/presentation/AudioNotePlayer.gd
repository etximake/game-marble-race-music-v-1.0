# AudioNotePlayer.gd
class_name AudioNotePlayer
extends Node

var players: Array[AudioStreamPlayer] = []

func _ready():
	setup_pool(16)

func setup_pool(pool_size: int) -> void:
	# Clear existing if any
	for p in players:
		if is_instance_valid(p):
			p.queue_free()
	players.clear()
	
	for i in range(pool_size):
		var p = AudioStreamPlayer.new()
		add_child(p)
		players.append(p)

func play_stream(stream: AudioStream, delay_seconds: float = 0.0) -> void:
	if not stream:
		return
		
	if delay_seconds > 0.0:
		await get_tree().create_timer(delay_seconds).timeout
		
	_play_stream(stream)

func stop_all() -> void:
	for p in players:
		if p.playing:
			p.stop()

func _play_stream(stream: AudioStream) -> void:
	# Find an idle player
	for p in players:
		if not p.playing:
			p.stream = stream
			p.play()
			return
	
	# If all players are busy, steal the oldest one
	var oldest_player = players[0]
	oldest_player.stream = stream
	oldest_player.play()
