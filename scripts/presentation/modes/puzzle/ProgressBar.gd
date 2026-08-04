# PuzzleProgressBar.gd
class_name PuzzleProgressBar
extends Node2D

var fill_ratio: float = 0.0
var played: int = 0
var total: int = 1
var bar_width: int = 800
var bar_height: int = 24
var time_elapsed: float = 0.0
var visible_self: bool = true

# Các tham số cho hiệu ứng hạt/lửa và nảy nhịp
var particles: Array = []
var pulse_scale: float = 1.0
var pulse_timer: float = 0.0

func setup():
	# Căn giữa hoàn toàn thanh tiến trình (1080 - 800) / 2 = 140
	# Đặt lùi xuống đáy màn hình ở Y = 1680
	position = Vector2(140, 1680)
	particles.clear()
	pulse_scale = 1.0
	pulse_timer = 0.0

func update_progress(p_played: int, p_total: int):
	played = p_played
	total = max(p_total, 1)
	fill_ratio = clampf(float(played) / float(total), 0.0, 1.0)

# Kích hoạt hiệu ứng giật nhẹ thanh progress theo nhịp nốt nhạc va chạm
func trigger_pulse():
	pulse_scale = 1.15
	pulse_timer = 0.15

func _process(delta):
	time_elapsed += delta
	
	# Cập nhật hiệu ứng co giãn nhịp
	if pulse_timer > 0.0:
		pulse_timer -= delta
		var t = 1.0 - (pulse_timer / 0.15)
		pulse_scale = lerpf(1.15, 1.0, t * t)
		if pulse_timer <= 0.0:
			pulse_scale = 1.0

	# Sinh hạt lửa nhỏ bám theo đầu thanh tiến trình (lead_x)
	if fill_ratio > 0.0 and fill_ratio < 1.0 and randf() < 0.35:
		var fill_width = max(bar_width * fill_ratio, bar_height)
		var lead_x = fill_width - (bar_height / 2.0)
		var hue = wrapf(time_elapsed * 0.15, 0.0, 1.0)
		var p_col = Color.from_hsv(hue, 0.9, 1.0, 0.8)
		
		# Thêm hạt
		particles.append({
			"pos": Vector2(lead_x, (bar_height / 2.0) + randf_range(-6.0, 6.0)),
			"vel": Vector2(randf_range(-120.0, -40.0), randf_range(-30.0, 30.0)),
			"color": p_col,
			"alpha": 1.0,
			"size": randf_range(3.0, 6.0)
		})

	# Cập nhật vị trí và độ mờ của hạt
	var i = particles.size() - 1
	while i >= 0:
		var p = particles[i]
		p["pos"] += p["vel"] * delta
		p["alpha"] -= delta * 2.2 # Hạt tan biến nhanh
		if p["alpha"] <= 0.0:
			particles.remove_at(i)
		i -= 1

	queue_redraw()

func _draw():
	var radius = bar_height / 2.0
	
	# Sử dụng ma trận biến đổi cục bộ để phóng to thanh progress theo tâm trục của nó khi nảy nhịp
	# Thay vì dùng draw_get_transform (không tồn tại trong CanvasItem/Node2D của Godot 4)
	# Chúng ta sử dụng draw_set_transform trực tiếp
	draw_set_transform(Vector2(0, bar_height / 2.0), 0.0, Vector2(1.0, pulse_scale))
	
	# Cấu hình Rect tương đối cho transform mới
	var draw_rect_bg = Rect2(0, -radius, bar_width, bar_height)
	
	# 1. Vẽ nền sau (Background)
	draw_style_box_flat(draw_rect_bg, Color(0.06, 0.06, 0.08, 0.92), radius)

	# 2. Vẽ phần đã lấp đầy (Fill bar)
	if fill_ratio > 0.0:
		var fill_width = max(bar_width * fill_ratio, bar_height)
		var draw_rect_fill = Rect2(0, -radius, fill_width, bar_height)
		var hue = wrapf(time_elapsed * 0.15, 0.0, 1.0)
		var fill_col = Color.from_hsv(hue, 0.85, 0.9, 0.95)
		draw_style_box_flat(draw_rect_fill, fill_col, radius)
		
		# Khôi phục ma trận vẽ để vẽ các hạt lửa và đốm sáng chính xác không bị scale bóp méo
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		
		# Vẽ đốm sáng neon dẫn đầu (lead glow)
		var lead_x = fill_width - radius
		draw_circle(Vector2(lead_x, radius), radius * 1.1, Color(1.0, 1.0, 1.0, 0.95))
		draw_circle(Vector2(lead_x, radius), radius * 1.7, Color(fill_col.r, fill_col.g, fill_col.b, 0.55))
		draw_circle(Vector2(lead_x, radius), radius * 2.6, Color(fill_col.r, fill_col.g, fill_col.b, 0.22))
		
		# Vẽ các hạt lửa (spark embers) bay lùi về sau
		for p in particles:
			var p_col = p["color"] as Color
			p_col.a = p["alpha"]
			draw_circle(p["pos"], p["size"], p_col)
			
		# Quay lại transform scale để vẽ viền đồng bộ
		draw_set_transform(Vector2(0, bar_height / 2.0), 0.0, Vector2(1.0, pulse_scale))

	# 3. Vẽ viền Neon mảnh bao quanh
	var border_hue = wrapf(time_elapsed * 0.15, 0.0, 1.0)
	var border_col = Color.from_hsv(border_hue, 0.85, 1.0, 0.4)
	draw_style_box_flat_border(draw_rect_bg, border_col, radius, 1.5)
	
	# Khôi phục hoàn toàn ma trận transform ban đầu
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# Hàm bổ trợ vẽ StyleBox bo tròn phẳng
func draw_style_box_flat(rect: Rect2, color: Color, r: float):
	var sb = StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(r)
	draw_style_box(sb, rect)

# Hàm bổ trợ vẽ viền StyleBox bo tròn
func draw_style_box_flat_border(rect: Rect2, color: Color, r: float, width: float):
	var sb = StyleBoxFlat.new()
	sb.draw_center = false
	sb.border_color = color
	sb.set_border_width_all(width)
	sb.set_corner_radius_all(r)
	draw_style_box(sb, rect)
