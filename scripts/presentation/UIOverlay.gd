# UIOverlay.gd
class_name UIOverlay
extends CanvasLayer

@onready var top_label: Label = $Control/TopLabel
@onready var bottom_label: Label = $Control/BottomLabel
@onready var countdown_label: Label = $Control/CountdownLabel

var is_showing_answer: bool = false
var blink_timer: float = 0.0
var original_bottom_text: String = ""

var is_puzzle_mode: bool = false
var is_countdown_active: bool = false
var countdown_value: int = 5
var countdown_timer: float = 0.0
var reveal_time: float = 20.0

var quiz_options: Array = []
var quiz_correct_index: int = -1
var quiz_labels: Array = []
var quiz_target_y: Array = []
var is_showing_quiz: bool = false

func setup(text_config: Dictionary, is_puzzle: bool = false):
	var show_text = text_config.get("show_text", true)
	visible = show_text
	is_showing_answer = false
	blink_timer = 0.0
	original_bottom_text = text_config.get("bottom_text", "")
	is_puzzle_mode = is_puzzle
	is_countdown_active = false
	countdown_value = 5
	countdown_timer = 0.0
	is_showing_quiz = false

	if show_text:
		top_label.text = text_config.get("top_text", "")
		bottom_label.text = original_bottom_text

		top_label.modulate.a = 1.0
		top_label.scale = Vector2.ONE

		# Thiết lập vị trí và kích thước động cho top_label (Hook) sát đỉnh tránh đè đáp án
		top_label.anchor_left = 0.5
		top_label.anchor_right = 0.5
		top_label.anchor_top = 0.0
		top_label.anchor_bottom = 0.0
		top_label.offset_left = -500.0
		top_label.offset_right = 500.0
		top_label.offset_top = 60.0
		top_label.offset_bottom = 160.0
		top_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		top_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		top_label.autowrap_mode = TextServer.AUTOWRAP_WORD # Cho phép tự động xuống hàng

		if is_puzzle:
			top_label.add_theme_font_size_override("font_size", 42)
		else:
			top_label.add_theme_font_size_override("font_size", 52)

		bottom_label.visible = not is_puzzle

		top_label.visible = top_label.text != ""

		bottom_label.anchor_top = 1.0
		bottom_label.anchor_bottom = 1.0
		bottom_label.offset_left = 80.0
		bottom_label.offset_right = -80.0
		bottom_label.offset_top = -120.0
		bottom_label.offset_bottom = -40.0
		bottom_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bottom_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		bottom_label.add_theme_font_size_override("font_size", 32)
		bottom_label.add_theme_color_override("font_color", Color(0, 0.9, 1, 1))

	if countdown_label:
		countdown_label.visible = false
		countdown_label.add_theme_font_size_override("font_size", 80)
		countdown_label.add_theme_color_override("font_color", Color(1, 0.85, 0.2, 1))
		countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		countdown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		countdown_label.anchor_left = 0.5
		countdown_label.anchor_right = 0.5
		countdown_label.anchor_top = 0.5
		countdown_label.anchor_bottom = 0.5
		countdown_label.offset_left = -200
		countdown_label.offset_right = 200
		countdown_label.offset_top = -100
		countdown_label.offset_bottom = 100

func setup_quiz(p_options: Array, p_correct_index: int = -1, p_reveal_time: float = 20.0):
	quiz_options = p_options
	quiz_correct_index = p_correct_index
	reveal_time = p_reveal_time
	is_showing_quiz = false

func start_countdown(p_current_time: float, p_reveal_time: float):
	reveal_time = p_reveal_time
	var time_until_reveal = p_reveal_time - p_current_time
	if time_until_reveal <= 0.0 or time_until_reveal > 6.0:
		return
	countdown_value = max(int(ceil(time_until_reveal)), 1)
	is_countdown_active = true
	countdown_timer = 0.0
	if countdown_label:
		countdown_label.visible = true
		countdown_label.text = str(countdown_value)

func update_countdown(p_current_time: float):
	if not is_countdown_active:
		if is_puzzle_mode and not is_showing_answer and p_current_time >= reveal_time - 5.0 and p_current_time < reveal_time:
			start_countdown(p_current_time, reveal_time)
		return

	var time_until_reveal = reveal_time - p_current_time
	if time_until_reveal <= 0.0:
		is_countdown_active = false
		if countdown_label:
			countdown_label.visible = false
		return

	var new_value = max(int(ceil(time_until_reveal)), 1)
	if new_value != countdown_value:
		countdown_value = new_value
		countdown_timer = 0.0
		if countdown_label:
			countdown_label.text = str(countdown_value)
			countdown_label.modulate = Color(1, 0.85, 0.2, 1)
			countdown_label.scale = Vector2(1.3, 1.3)

	countdown_timer += 0.0
	if countdown_label and countdown_label.visible:
		var pulse = 1.0 + 0.08 * sin(countdown_timer * 4.0)
		countdown_label.scale = countdown_label.scale.lerp(Vector2(pulse, pulse), 0.2)

func _process(delta: float):
	if is_showing_answer and top_label:
		blink_timer += delta * 6.0
		var alpha = 0.35 + 0.65 * absf(sin(blink_timer))
		top_label.modulate.a = alpha
		var scale_val = 1.0 + 0.1 * absf(sin(blink_timer * 0.5))
		top_label.scale = Vector2(scale_val, scale_val)

	if is_countdown_active and countdown_label:
		countdown_timer += delta

	# Smooth quiz entrance animation
	if is_showing_quiz:
		for i in range(quiz_labels.size()):
			if is_instance_valid(quiz_labels[i]):
				var label = quiz_labels[i]
				var target_y = quiz_target_y[i]
				var curr_top = label.offset_top
				# Interpolate position (slide up)
				var next_top = lerpf(curr_top, target_y, delta * 7.0)
				var height = label.offset_bottom - label.offset_top
				label.offset_top = next_top
				label.offset_bottom = next_top + height
				# Interpolate opacity for fade in
				if not is_showing_answer:
					label.modulate.a = lerpf(label.modulate.a, 1.0, delta * 7.0)

func show_answer(song_name: String):
	if not top_label:
		return
	is_showing_answer = true
	is_countdown_active = false
	if countdown_label:
		countdown_label.visible = false
	
	# Ẩn hoàn toàn các lựa chọn để nhường chỗ cho đáp án to rõ ràng
	hide_quiz_options()
	
	blink_timer = 0.0
	var answer_text = song_name
	if answer_text == "":
		answer_text = "Cupid - Fifty Fifty"
	top_label.text = answer_text
	top_label.visible = true
	top_label.add_theme_font_size_override("font_size", 72)
	top_label.pivot_offset = top_label.size / 2.0

	if bottom_label:
		if original_bottom_text != "":
			bottom_label.text = original_bottom_text
		else:
			bottom_label.text = "Ban doan dung khong? Comment ben duoi nhe!"
		bottom_label.visible = true

func show_quiz_options():
	if quiz_options.is_empty() or is_showing_quiz:
		return
	is_showing_quiz = true
	_draw_quiz_options()

func hide_quiz_options():
	is_showing_quiz = false
	for label in quiz_labels:
		if is_instance_valid(label):
			label.queue_free()
	quiz_labels.clear()

func highlight_correct_answer():
	if not is_showing_quiz or quiz_correct_index < 0:
		return
	for i in range(quiz_labels.size()):
		if is_instance_valid(quiz_labels[i]):
			var sb = quiz_labels[i].get_theme_stylebox("normal").duplicate() as StyleBoxFlat
			if i == quiz_correct_index:
				quiz_labels[i].add_theme_color_override("font_color", Color(0, 1, 0.5, 1))
				quiz_labels[i].scale = Vector2(1.15, 1.15)
				quiz_labels[i].pivot_offset = quiz_labels[i].size / 2.0
				if sb:
					sb.border_color = Color(0, 1.0, 0.5, 1.0)
					sb.bg_color = Color(0, 0.15, 0.08, 0.85)
					quiz_labels[i].add_theme_stylebox_override("normal", sb)
			else:
				quiz_labels[i].modulate.a = 0.35
				quiz_labels[i].add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.6))
				if sb:
					sb.border_color = Color(0.15, 0.15, 0.15, 0.2)
					sb.bg_color = Color(0.04, 0.04, 0.05, 0.3)
					quiz_labels[i].add_theme_stylebox_override("normal", sb)

func _draw_quiz_options():
	var option_labels = ["A", "B", "C"]
	var option_count = min(quiz_options.size(), 3)
	var spacing = 70
	var start_y = 200.0

	quiz_target_y.clear()
	for i in range(option_count):
		var label = Label.new()
		var text = option_labels[i] + ". " + quiz_options[i]
		label.text = text
		label.add_theme_font_size_override("font_size", 32)
		label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9, 1.0))
		label.modulate.a = 0.0 # Bắt đầu ẩn để fade-in
		
		# Thiết lập viền chữ
		label.add_theme_constant_override("outline_size", 6)
		label.add_theme_color_override("font_outline_color", Color(0.04, 0.04, 0.06, 1.0))
		
		# Nền nút bấm đẹp mắt bo tròn phía sau chữ có neon border mảnh và padding
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.04, 0.04, 0.06, 0.72)
		sb.set_border_width_all(1.5)
		sb.border_color = Color(0.18, 0.6, 0.8, 0.6) # Viền neon cyan mảnh
		sb.set_corner_radius_all(14)
		sb.content_margin_left = 25
		sb.content_margin_right = 25
		sb.content_margin_top = 10
		sb.content_margin_bottom = 10
		label.add_theme_stylebox_override("normal", sb)
		
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.anchor_left = 0.5
		label.anchor_right = 0.5
		
		var t_y = start_y + float(i) * spacing
		quiz_target_y.append(t_y)
		
		# Xuất phát trễ Y (slide-up)
		label.offset_left = -400
		label.offset_right = 400
		label.offset_top = t_y + 40.0
		label.offset_bottom = t_y + 40.0 + spacing - 10.0
		
		$Control.add_child(label)
		quiz_labels.append(label)