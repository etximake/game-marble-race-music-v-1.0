# UIOverlay.gd
class_name UIOverlay
extends CanvasLayer

@onready var top_label: Label = $Control/TopLabel
@onready var bottom_label: Label = $Control/BottomLabel
@onready var countdown_label: Label = $Control/CountdownLabel

var is_showing_answer: bool = false
var blink_timer: float = 0.0
var original_bottom_text: String = ""

func setup(text_config: Dictionary):
	var show_text = text_config.get("show_text", true)
	visible = show_text
	is_showing_answer = false
	blink_timer = 0.0
	original_bottom_text = text_config.get("bottom_text", "")
	
	if show_text:
		top_label.text = text_config.get("top_text", "")
		bottom_label.text = original_bottom_text
		
		# Reset any override from previous runs
		top_label.modulate.a = 1.0
		top_label.add_theme_font_size_override("font_size", 52)
		top_label.scale = Vector2.ONE
		
		# Ẩn bottom_label ở giai đoạn đầu game để sạch sẽ, chỉ hiện khi công bố đáp án
		bottom_label.visible = false
		
		# Set custom fonts or sizes if needed, or stick to defaults
		top_label.visible = top_label.text != ""
		
		# Điều chỉnh vị trí của bottom_label xuống phía dưới cùng màn hình (Y = 1580)
		# Tránh đè lên Arena (trung tâm 1080, bán kính 470 -> đáy 1550) và trail của bóng
		bottom_label.anchor_top = 1.0
		bottom_label.anchor_bottom = 1.0
		bottom_label.offset_left = 80.0
		bottom_label.offset_right = -80.0
		bottom_label.offset_top = -340.0    # Cố định Y = 1580px (1920 - 340)
		bottom_label.offset_bottom = -260.0 # Cố định Y = 1660px (1920 - 260)
		bottom_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bottom_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		bottom_label.add_theme_font_size_override("font_size", 32)
		bottom_label.add_theme_color_override("font_color", Color(0, 0.9, 1, 1))
		
	if countdown_label:
		countdown_label.visible = false

func _process(delta: float):
	if is_showing_answer and top_label:
		blink_timer += delta * 6.0
		var alpha = 0.35 + 0.65 * absf(sin(blink_timer))
		top_label.modulate.a = alpha
		# Smoothly pulse scale
		var scale_val = 1.0 + 0.1 * absf(sin(blink_timer * 0.5))
		top_label.scale = Vector2(scale_val, scale_val)

func show_answer(song_name: String):
	if not top_label:
		return
	is_showing_answer = true
	blink_timer = 0.0
	var answer_text = song_name
	if answer_text == "":
		answer_text = "Cupid - Fifty Fifty" # Fallback if empty
	top_label.text = answer_text
	top_label.visible = true
	top_label.add_theme_font_size_override("font_size", 72)
	# Center pivot for scaling/rotation animation correctly
	top_label.pivot_offset = top_label.size / 2.0
	
	if bottom_label:
		# Lấy text đã định cấu hình trong video_config.json nếu có, nếu không lấy text mặc định
		if original_bottom_text != "":
			bottom_label.text = original_bottom_text
		else:
			bottom_label.text = "Bạn đoán đúng không? Comment bên dưới nhé! 👇"
		bottom_label.visible = true # Hiện bottom text khi công bố đáp án ở 6 giây cuối

func update_countdown(current_time: float, reveal_time: float):
	if not countdown_label:
		return
	# Vô hiệu hóa hiển thị số đếm ngược 3-2-1 để vào nhạc/va chạm ngay lập tức
	countdown_label.visible = false
