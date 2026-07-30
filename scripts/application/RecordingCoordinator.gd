# RecordingCoordinator.gd
class_name RecordingCoordinator
extends RefCounted

var recording: bool = false
var video_config: VideoConfig

var frame_recorder: ViewportFrameRecorder
var timeline_recorder: AudioTimelineRecorder
var video_encoder: VideoEncoder

var session_dir: String = ""
var output_mp4_path: String = ""
var temp_audio_path: String = ""
var temp_timeline_path: String = ""

var current_frame_idx: int = 0
var record_fps: int = 60
var total_duration: float = 0.0
var last_saved_image: Image = null
var original_window_size: Vector2i = Vector2i.ZERO
var _headless_warned: bool = false

func _init():
	frame_recorder = ViewportFrameRecorder.new()
	timeline_recorder = AudioTimelineRecorder.new()
	video_encoder = VideoEncoder.new()
	recording = false

func is_recording() -> bool:
	return recording

func start_recording(config: VideoConfig, job_folder: String, window: Window) -> void:
	if recording:
		return
		
	video_config = config
	total_duration = config.get_duration()
	record_fps = config.get_video_fps()
	if record_fps <= 0:
		record_fps = 60
		
	if DisplayServer.get_name() != "headless" and window:
		original_window_size = window.size
		var target_w = config.get_video_width()
		var target_h = config.get_video_height()
		window.size = Vector2i(target_w, target_h)
		print("RecordingCoordinator: Resized window from ", original_window_size, " to ", window.size)
		
	var output_name = config.get_output_name()
	if output_name == "":
		output_name = "output"
		
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-")
	
	# Determine paths
	var output_base_dir = "res://output/godot_renders"
	# Convert res:// to absolute path if needed
	var absolute_base_dir = ProjectSettings.globalize_path(output_base_dir)
	
	session_dir = absolute_base_dir.path_join(".sessions").path_join(output_name + "_" + timestamp)
	output_mp4_path = absolute_base_dir.path_join(output_name + ".mp4")
	temp_audio_path = session_dir.path_join("temp_audio.wav")
	temp_timeline_path = session_dir.path_join("temp_timeline.json")
	
	# Create directory
	if DirAccess.dir_exists_absolute(session_dir):
		_delete_dir_recursive(session_dir)
	DirAccess.make_dir_recursive_absolute(session_dir)
	
	timeline_recorder = AudioTimelineRecorder.new()
	timeline_recorder.duration = total_duration
	
	current_frame_idx = 0
	last_saved_image = null
	recording = true
	frame_recorder.start()
	
	print("RecordingCoordinator: Started recording session. Output: ", output_mp4_path)
	print("RecordingCoordinator: Session temp folder: ", session_dir)

func capture_frame(viewport: Viewport, current_time: float) -> void:
	if not recording or not viewport:
		return
		
	if DisplayServer.get_name() == "headless":
		if not _headless_warned:
			printerr("RecordingCoordinator: Cannot capture frames in headless mode because there is no GPU rendering backbuffer texture. Run Godot in windowed mode (without --headless) to record video.")
			_headless_warned = true
		return
		
	# Determine target frame number (1-based)
	var target_frame = int(floor(current_time * record_fps)) + 1
	var max_frame = int(ceil(total_duration * record_fps))
	if target_frame > max_frame:
		target_frame = max_frame
		
	if target_frame <= current_frame_idx:
		# Already captured this frame index, skip
		return
		
	var texture = viewport.get_texture()
	if not texture:
		return
	var img = texture.get_image()
	if not img or img.is_empty():
		return
		
	# Write frame PNG
	var frame_name = "frame_%06d.png" % target_frame
	var frame_path = session_dir.path_join(frame_name)
	frame_recorder.queue_image(img, frame_path)
	
	# Catch up in case we skipped frames (physics/process delta mismatch)
	if current_frame_idx > 0 and target_frame > current_frame_idx + 1:
		if last_saved_image and not last_saved_image.is_empty():
			for f in range(current_frame_idx + 1, target_frame):
				var fill_name = "frame_%06d.png" % f
				var fill_path = session_dir.path_join(fill_name)
				frame_recorder.queue_image(last_saved_image, fill_path)
				
	current_frame_idx = target_frame
	last_saved_image = img

func stop_recording(repository: AudioAssetRepository) -> void:
	if not recording:
		return
		
	recording = false
	print("RecordingCoordinator: Stopping recording. Total frames captured: ", current_frame_idx)
	
	if DisplayServer.get_name() != "headless" and original_window_size != Vector2i.ZERO:
		var window = Engine.get_main_loop().get_root()
		if window:
			window.size = original_window_size
			print("RecordingCoordinator: Restored window size to ", original_window_size)
	
	if current_frame_idx == 0:
		frame_recorder.stop()
		print("RecordingCoordinator: No frames were captured. Skipping video encoding.")
		_delete_dir_recursive(session_dir)
		return
	
	# Verify that we filled up to the last frame
	var max_frame = int(ceil(total_duration * record_fps))
	if current_frame_idx < max_frame and last_saved_image and not last_saved_image.is_empty():
		for f in range(current_frame_idx + 1, max_frame + 1):
			var fill_name = "frame_%06d.png" % f
			var fill_path = session_dir.path_join(fill_name)
			frame_recorder.queue_image(last_saved_image, fill_path)
		current_frame_idx = max_frame
		
	# Wait for all queued frames to finish writing
	frame_recorder.stop()
	
	# Save audio timeline
	timeline_recorder.save_timeline(temp_timeline_path)
	
	# Mix audio
	print("RecordingCoordinator: Mixing audio tracks...")
	var mix_success = video_encoder.mix_audio(
		timeline_recorder.events,
		total_duration,
		repository,
		temp_audio_path
	)
	
	if not mix_success:
		printerr("RecordingCoordinator: Audio mixing failed. Keep temporary session files at: ", session_dir)
		return
		
	# Encode video
	print("RecordingCoordinator: Encoding video via FFmpeg...")
	var frames_pattern = session_dir.path_join("frame_%06d.png")
	var encode_success = video_encoder.encode_video(
		frames_pattern,
		temp_audio_path,
		record_fps,
		output_mp4_path
	)
	
	if encode_success:
		# Clean up temporary session files
		print("RecordingCoordinator: Cleaning up temporary files...")
		_delete_dir_recursive(session_dir)
		print("RecordingCoordinator: Recording pipeline finished successfully!")
	else:
		printerr("RecordingCoordinator: Video encoding failed. Keep temporary session files at: ", session_dir)

func _delete_dir_recursive(path: String) -> void:
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name != "." and file_name != "..":
				if dir.current_is_dir():
					_delete_dir_recursive(path.path_join(file_name))
				else:
					dir.remove(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
		DirAccess.remove_absolute(path)
