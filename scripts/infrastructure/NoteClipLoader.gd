# NoteClipLoader.gd
class_name NoteClipLoader
extends RefCounted

static func load_note_clip(path: String) -> AudioStream:
	if not FileAccess.file_exists(path):
		printerr("NoteClipNotFound: " + path)
		return null
	
	# Generated WAV files are not imported Godot resources. Parse them directly
	# before attempting resource loading.
	if not path.to_lower().ends_with(".wav") and (path.begins_with("res://") or path.begins_with("user://")):
		var imported_stream = load(path)
		if imported_stream is AudioStream:
			return imported_stream

	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		printerr("AudioLoadFailed: Cannot open file " + path)
		return null
	
	var bytes = file.get_buffer(file.get_length())
	file.close()
	
	if path.ends_with(".wav"):
		var stream = AudioStreamWAV.new()
		# Minimum WAV parsing logic or direct data binding
		# Note: In Godot 4, setting bytes directly might not parse headers automatically, but AudioStreamWAV has limits.
		# Let's check if load() works for files in workspace directory. Yes, in Godot, absolute paths or res:// paths to workspace work.
		# If the path is absolute like D:/..., load() might fail if not imported.
		# To handle external wav files, we parse the wav header or set data directly if it's headerless.
		# Let's write a robust external WAV loader if needed, or try to load as AudioStreamWAV.
		# A simpler way in Godot is to load the file bytes and parse the WAV format.
		# Here is a basic WAV header parser:
		if bytes.size() < 44:
			printerr("AudioLoadFailed: Invalid WAV file size: " + path)
			return null
		
		# Validate RIFF WAV header
		if bytes.decode_u32(0) != 0x46464952 or bytes.decode_u32(8) != 0x45564157: # "RIFF" and "WAVE"
			printerr("AudioLoadFailed: Not a valid RIFF WAVE file: " + path)
			return null
		
		# Find fmt chunk and data chunk
		var offset = 12
		var format = AudioStreamWAV.FORMAT_16_BITS
		var mix_rate = 44100
		var stereo = false
		var data_offset = 0
		var data_size = 0
		
		while offset < bytes.size() - 8:
			var chunk_id = bytes.decode_u32(offset)
			var chunk_size = bytes.decode_u32(offset + 4)
			offset += 8
			
			if chunk_id == 0x20746d66: # "fmt "
				var audio_format = bytes.decode_u16(offset)
				var channels = bytes.decode_u16(offset + 2)
				mix_rate = bytes.decode_u32(offset + 4)
				var bits_per_sample = bytes.decode_u16(offset + 14)
				
				stereo = (channels == 2)
				if bits_per_sample == 8:
					format = AudioStreamWAV.FORMAT_8_BITS
				elif bits_per_sample == 16:
					format = AudioStreamWAV.FORMAT_16_BITS
				else:
					# Let's default or raise
					format = AudioStreamWAV.FORMAT_16_BITS
				
				offset += chunk_size
			elif chunk_id == 0x61746164: # "data"
				data_offset = offset
				data_size = chunk_size
				break
			else:
				offset += chunk_size
		
		if data_offset > 0 and data_size > 0:
			stream.format = format
			stream.mix_rate = mix_rate
			stream.stereo = stereo
			stream.data = bytes.slice(data_offset, data_offset + data_size)
			return stream
		else:
			# Try loading using load() directly if it's imported or can be loaded by Godot
			var res_stream = load(path)
			if res_stream is AudioStream:
				return res_stream
	
	printerr("AudioLoadFailed: Unsupported audio format or loading failed for: " + path)
	return null
