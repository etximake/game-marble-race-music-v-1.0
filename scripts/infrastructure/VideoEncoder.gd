# VideoEncoder.gd
class_name VideoEncoder
extends RefCounted

func _get_wav_header(data_size: int, sample_rate: int, channels: int, bits_per_sample: int) -> PackedByteArray:
	var header = PackedByteArray()
	header.resize(44)
	
	# "RIFF"
	header.encode_u32(0, 0x46464952)
	header.encode_u32(4, data_size + 36)
	# "WAVE"
	header.encode_u32(8, 0x45564157)
	# "fmt "
	header.encode_u32(12, 0x20746d66)
	header.encode_u32(16, 16) # Chunk size
	header.encode_u16(20, 1) # Audio format (PCM = 1)
	header.encode_u16(22, channels)
	header.encode_u32(24, sample_rate)
	
	var bytes_per_sample = bits_per_sample / 8
	var byte_rate = sample_rate * channels * bytes_per_sample
	var block_align = channels * bytes_per_sample
	
	header.encode_u32(28, byte_rate)
	header.encode_u16(32, block_align)
	header.encode_u16(34, bits_per_sample)
	# "data"
	header.encode_u32(36, 0x61746164)
	header.encode_u32(40, data_size)
	
	return header

func mix_audio(events: Array, duration: float, repository: AudioAssetRepository, output_wav_path: String) -> bool:
	var sample_rate = 44100
	var channels = 2
	var bits_per_sample = 16
	var bytes_per_sample = 2
	
	var total_samples = int(duration * sample_rate)
	var data_size = total_samples * channels * bytes_per_sample
	
	var pcm_data = PackedByteArray()
	pcm_data.resize(data_size) # Filled with zeros
	
	for event in events:
		var event_time = float(event.get("time", 0.0))
		var start_sample = int(event_time * sample_rate)
		if start_sample >= total_samples:
			continue
			
		var stream: AudioStreamWAV = null
		var is_source = (event.get("type", "") == "source")
		
		if is_source:
			var source_file = event.get("file", "")
			stream = repository.load_source_stream(source_file) as AudioStreamWAV
		else:
			var note_file = event.get("file", "")
			stream = repository.load_note_stream(note_file) as AudioStreamWAV
			
		if not stream:
			continue
			
		var clip_data = stream.data
		var clip_mix_rate = stream.mix_rate
		var clip_stereo = stream.stereo
		var clip_format = stream.format
		
		var clip_sample_size = 2 if clip_format == AudioStreamWAV.FORMAT_16_BITS else 1
		var clip_channels = 2 if clip_stereo else 1
		var clip_sample_count = clip_data.size() / (clip_sample_size * clip_channels)
		
		# For source audio transition, we seek to the start_position
		var clip_start_offset_samples = 0
		if is_source:
			var start_pos_seconds = float(event.get("start_position", 0.0))
			clip_start_offset_samples = int(start_pos_seconds * clip_mix_rate)
			
		for i in range(clip_sample_count - clip_start_offset_samples):
			var out_sample_idx = start_sample + i
			if out_sample_idx >= total_samples:
				break
				
			var clip_sample_idx = clip_start_offset_samples + i
			
			var left_val = 0
			var right_val = 0
			
			if clip_format == AudioStreamWAV.FORMAT_16_BITS:
				if clip_stereo:
					var base_byte = clip_sample_idx * 4
					if base_byte + 3 < clip_data.size():
						left_val = clip_data.decode_s16(base_byte)
						right_val = clip_data.decode_s16(base_byte + 2)
				else:
					var base_byte = clip_sample_idx * 2
					if base_byte + 1 < clip_data.size():
						left_val = clip_data.decode_s16(base_byte)
						right_val = left_val
			else: # FORMAT_8_BITS
				if clip_stereo:
					var base_byte = clip_sample_idx * 2
					if base_byte + 1 < clip_data.size():
						left_val = (int(clip_data[base_byte]) - 128) * 256
						right_val = (int(clip_data[base_byte + 1]) - 128) * 256
				else:
					var base_byte = clip_sample_idx
					if base_byte < clip_data.size():
						left_val = (int(clip_data[base_byte]) - 128) * 256
						right_val = left_val
						
			# Read current values in output buffer
			var out_base_byte = out_sample_idx * 4
			var current_out_l = pcm_data.decode_s16(out_base_byte)
			var current_out_r = pcm_data.decode_s16(out_base_byte + 2)
			
			# Mix and clamp
			var mixed_l = clamp(current_out_l + left_val, -32768, 32767)
			var mixed_r = clamp(current_out_r + right_val, -32768, 32767)
			
			pcm_data.encode_s16(out_base_byte, mixed_l)
			pcm_data.encode_s16(out_base_byte + 2, mixed_r)
			
	# Save WAV to file
	var dir = output_wav_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)
		
	var header = _get_wav_header(data_size, sample_rate, channels, bits_per_sample)
	var file = FileAccess.open(output_wav_path, FileAccess.WRITE)
	if not file:
		printerr("VideoEncoder: Failed to open output WAV file for writing: ", output_wav_path)
		return false
		
	file.store_buffer(header)
	file.store_buffer(pcm_data)
	file.close()
	return true

func encode_video(frames_pattern: String, audio_path: String, fps: int, output_mp4_path: String) -> bool:
	var output_dir = output_mp4_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(output_dir):
		DirAccess.make_dir_recursive_absolute(output_dir)
		
	var args = [
		"-y",
		"-framerate", str(fps),
		"-i", frames_pattern,
		"-i", audio_path,
		"-c:v", "libx264",
		"-pix_fmt", "yuv420p",
		"-c:a", "aac",
		"-shortest",
		output_mp4_path
	]
	
	print("VideoEncoder: Executing FFmpeg command: ffmpeg ", " ".join(args))
	
	var output = []
	var exit_code = OS.execute("ffmpeg", args, output, true, false)
	if exit_code != 0:
		printerr("VideoEncoder: FFmpeg failed with exit code: ", exit_code, " Output: ", "".join(output))
		return false
		
	print("VideoEncoder: FFmpeg completed successfully. Output video saved at: ", output_mp4_path)
	return true
