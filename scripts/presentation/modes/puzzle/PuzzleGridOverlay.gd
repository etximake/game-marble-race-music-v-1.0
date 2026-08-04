# PuzzleGridOverlay.gd
class_name PuzzleGridOverlay
extends Node2D

# Cấu hình đĩa than tròn đồng tâm 500px chính giữa Arena (540, 1080)
const ALBUM_SIZE = 640
const REVEAL_SLICES = 8 # Chia nhãn tròn làm 8 mảnh hình quạt để mở

var image_texture: Texture2D = null
var revealed: Array = []
var reveal_count: int = 0
var total_cells: int = REVEAL_SLICES # Đồng bộ số mảnh
var is_complete: bool = false
var reveal_target: int = 0
var phase_reveal_targets = [1, 2, 4, 8] # Tiến độ lộ diện theo từng phase

var spin_angle: float = 0.0
var show_glow: bool = false
var glow_timer: float = 0.0

# Vết đĩa than
var center_offset: Vector2 = Vector2(540, 1080)

func setup(p_image_path: String, p_top_text: String, p_job_folder: String):
	reveal_target = 0
	reveal_count = 0
	is_complete = false
	revealed.clear()
	for i in range(REVEAL_SLICES):
		revealed.append(false)

	# Bỏ hoàn toàn top_text và answer_label đè lên ảnh (Main UI đã hiển thị ở Header)
	if p_image_path != "":
		_load_image(p_image_path, p_job_folder)
		
	# Đặt vị trí cục bộ ở tâm Arena để dễ vẽ xoay tròn đồng tâm
	position = Vector2.ZERO
	z_index = 2 # Đặt dưới bóng (z_index=5) và có thể trên hoặc dưới trail tùy cấu hình z_index

func _load_image(p_path: String, p_job_folder: String):
	var img = Image.new()
	var final_path = p_path
	if not final_path.begins_with("res://") and p_job_folder != "":
		final_path = p_job_folder.path_join(final_path)
	if not final_path.begins_with("res://"):
		final_path = "res://" + final_path
	var err = img.load(final_path)
	if err == OK:
		img.resize(ALBUM_SIZE, ALBUM_SIZE, Image.INTERPOLATE_LANCZOS)
		image_texture = ImageTexture.create_from_image(img)

func reveal_cells(count: int):
	var unrevealed = []
	for i in range(total_cells):
		if not revealed[i]:
			unrevealed.append(i)

	unrevealed.shuffle()
	for j in range(min(count, unrevealed.size())):
		var idx = unrevealed[j]
		revealed[idx] = true
		reveal_count += 1

	if reveal_count >= total_cells:
		is_complete = true
		_trigger_complete_glow()

func reveal_by_phase(current_time: float, duration: float, phases: Array):
	if is_complete or duration <= 0.0:
		return

	var phase_idx = 0
	if not phases.is_empty():
		for p in range(phases.size()):
			var end_time = float(phases[p].get("end_time", 0.0))
			if current_time >= end_time:
				phase_idx = p

	var target = phase_reveal_targets[min(phase_idx, phase_reveal_targets.size() - 1)]
	target = min(target, total_cells)

	while reveal_target < target:
		reveal_target += 1
		reveal_cells(1)

func reveal_all():
	for i in range(total_cells):
		revealed[i] = true
	reveal_count = total_cells
	is_complete = true
	_trigger_complete_glow()

func _trigger_complete_glow():
	show_glow = true
	glow_timer = 1.0

func _process(delta: float):
	# Xoay đĩa than nhẹ nhàng 15 độ mỗi giây
	spin_angle += deg_to_rad(15.0) * delta
	if spin_angle > TAU:
		spin_angle -= TAU

	if show_glow:
		glow_timer -= delta
		if glow_timer <= 0.0:
			show_glow = false
	queue_redraw()

func _draw():
	var radius = ALBUM_SIZE / 2.0
	
	# 1. Vẽ đế đĩa than đen bóng
	draw_circle(center_offset, radius, Color(0.06, 0.06, 0.08, 0.95))
	
	# Vẽ các rãnh vinyl grooves đồng tâm siêu mảnh
	for i in range(6):
		var r = radius - 15.0 - float(i) * 30.0
		if r > 40.0:
			draw_arc(center_offset, r, 0, TAU, 180, Color(0.18, 0.18, 0.22, 0.4), 1.0, true)

	# 2. Vẽ ảnh Album Art ở giữa (bo tròn hoàn hảo)
	if image_texture:
		var old_transform = get_canvas_transform()
		# Dịch chuyển tâm và xoay bằng cách vẽ thủ công hoặc tính toán toạ độ xoay của các phân vùng
		# Thay vì dùng draw_get_transform (không tồn tại trong CanvasItem/Node2D của Godot 4, bản chất là draw_set_transform)
		# Chúng ta sử dụng draw_set_transform có sẵn của CanvasItem
		draw_set_transform(center_offset, spin_angle, Vector2.ONE)
		
		# Nhãn đĩa tròn trung tâm (đường kính 420px, bán kính 210px để lộ viền đĩa than đen ở ngoài)
		var label_r = 280.0
		var label_size = label_r * 2.0
		var rect = Rect2(-label_r, -label_r, label_size, label_size)
		
		# Vẽ ảnh
		draw_texture_rect(image_texture, rect, false)
		
		# Vẽ các mảnh che tối chưa được reveal
		var slice_angle = TAU / REVEAL_SLICES
		for i in range(REVEAL_SLICES):
			if not revealed[i]:
				var points = PackedVector2Array()
				points.append(Vector2.ZERO)
				var start_a = float(i) * slice_angle
				var end_a = float(i + 1) * slice_angle
				# Vẽ đa giác hình quạt
				var steps = 12
				for step in range(steps + 1):
					var a = start_a + (end_a - start_a) * (float(step) / float(steps))
					points.append(Vector2(cos(a), sin(a)) * label_r)
				
				# Phủ màu đen mờ che ảnh
				draw_polygon(points, PackedColorArray([Color(0.08, 0.08, 0.1, 0.98)]))
				# Vẽ đường line chia các mảnh
				draw_line(Vector2.ZERO, Vector2(cos(start_a), sin(start_a)) * label_r, Color(0.02, 0.02, 0.04, 0.5), 1.5, true)
		
		# Reset lại transform về mặc định
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		
		# 3. Vẽ tâm trục đĩa (Spindle Hole) bóng bẩy
		draw_circle(center_offset, 24.0, Color(0.1, 0.1, 0.12, 1.0))
		draw_circle(center_offset, 10.0, Color(0.02, 0.02, 0.02, 1.0))
		draw_arc(center_offset, 24.0, 0, TAU, 64, Color(0.5, 0.5, 0.55, 0.8), 2.0, true)

	# 4. Hiệu ứng viền phát sáng khi ghép xong đĩa
	if show_glow:
		var progress = 1.0 - (glow_timer / 1.0)
		var alpha = sin(progress * PI * 2.0) * 0.4 + 0.4
		var hue = wrapf(progress * 0.5, 0.0, 1.0)
		var col = Color.from_hsv(hue, 0.9, 1.0, alpha)
		draw_arc(center_offset, radius + 4.0, 0, TAU, 180, col, 6.0, true)
