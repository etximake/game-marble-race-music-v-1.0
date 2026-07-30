# ViewportFrameRecorder.gd
class_name ViewportFrameRecorder
extends RefCounted

var queue: Array = []
var queue_mutex: Mutex
var queue_semaphore: Semaphore
var worker_thread: Thread
var exit_thread: bool = false
var is_active: bool = false

func _init():
	queue_mutex = Mutex.new()
	queue_semaphore = Semaphore.new()
	is_active = false

func start() -> void:
	if is_active:
		return
	queue.clear()
	exit_thread = false
	is_active = true
	worker_thread = Thread.new()
	worker_thread.start(Callable(self, "_thread_func"))

func capture_frame(viewport: Viewport, frame_path: String) -> bool:
	if not is_active or not viewport:
		return false
		
	var texture = viewport.get_texture()
	if not texture:
		return false
		
	var image = texture.get_image()
	if not image or image.is_empty():
		return false
		
	# Push to queue
	queue_mutex.lock()
	queue.append({
		"image": image,
		"path": frame_path
	})
	queue_mutex.unlock()
	
	# Wake up thread
	queue_semaphore.post()
	return true

func queue_image(image: Image, frame_path: String) -> bool:
	if not is_active or not image or image.is_empty():
		return false
		
	queue_mutex.lock()
	queue.append({
		"image": image,
		"path": frame_path
	})
	queue_mutex.unlock()
	
	queue_semaphore.post()
	return true

func _thread_func() -> void:
	while true:
		queue_semaphore.wait() # Wait for work
		
		queue_mutex.lock()
		if exit_thread and queue.is_empty():
			queue_mutex.unlock()
			break
			
		if queue.is_empty():
			queue_mutex.unlock()
			continue
			
		var task = queue.pop_front()
		queue_mutex.unlock()
		
		var image = task["image"] as Image
		var path = task["path"] as String
		
		# Ensure directory exists before saving
		var dir = path.get_base_dir()
		if not DirAccess.dir_exists_absolute(dir):
			DirAccess.make_dir_recursive_absolute(dir)
			
		var err = image.save_png(path)
		if err != OK:
			printerr("ViewportFrameRecorder: Failed to save frame PNG to: ", path, " error: ", err)

func stop() -> void:
	if not is_active:
		return
		
	queue_mutex.lock()
	exit_thread = true
	queue_mutex.unlock()
	
	# Wake up thread to exit
	queue_semaphore.post()
	
	if worker_thread and worker_thread.is_started():
		worker_thread.wait_to_finish()
		
	is_active = false
	worker_thread = null
