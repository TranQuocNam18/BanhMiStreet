# Customer.gd
# Handles patience, Vietnamese phrases, cart comments, customer TYPES, and animations.

extends Node2D

signal customer_served(success: bool, earned: int)

# ── Customer Types ────────────────────────────────────────────────────────────
enum Type { NORMAL, GRAB, OFFICE, STUDENT }

var customer_type: Type = Type.NORMAL

const TYPE_LABELS = {
	Type.NORMAL: "",
	Type.GRAB:   "🛵 GRAB",
	Type.OFFICE: "👔 NV Văn Phòng",
	Type.STUDENT:"🎒 Học Sinh",
}
const TYPE_COLORS = {
	Type.NORMAL: Color(0.35, 0.55, 0.85), # dynamically overridden later
	Type.GRAB:   Color(0.07, 0.55, 0.15), # Grab green
	Type.OFFICE: Color(0.85, 0.85, 0.88), # Light shirt
	Type.STUDENT:Color(1.0, 1.0, 1.0),    # White shirt
}

# ── Phrases ───────────────────────────────────────────────────────────────────
const ARRIVE_PHRASES = {
	Type.NORMAL: ["Cho tôi bánh mì!", "Bán cho tôi với!", "Có bánh mì không?"],
	Type.GRAB:   ["Order Grab đây!", "Giao hàng nhanh lên!", "Khách đang đợi!"],
	Type.OFFICE: ["Cho tôi bữa sáng nhanh!", "Sắp trễ giờ làm rồi!", "Làm nhanh cho tôi nhé."],
	Type.STUDENT:["Cô chú ơi bán cho con!", "Cho con ổ rẻ nhất!", "Nhanh cô ơi tới giờ học rồi!"],
}
const CART_COMMENTS = [
	"Xe này trông cũ quá!",   "Sao không có ghế?",
	"Trời nắng thế này...",   "Xe cũ nhưng bánh ngon!",
	"Biển hiệu đẹp đó!",      "Sao không có đá?",
	"Ồ, có nhạc hay đấy!",    "Sạch sẽ quá!",
]
const HURRY_PHRASES = ["Nhanh lên!", "Chờ lâu quá!", "Vội lắm!", "Nhanh không?!"]
const HAPPY_PHRASES  = ["Cảm ơn nhé! 😊", "Ngon lắm!", "Tuyệt vời!", "Lần sau ghé nữa!"]
const LEAVE_PHRASES  = ["Thôi bỏ qua...", "Chậm quá!", "Đi chỗ khác!", "Lần sau nhanh hơn!"]
const WRONG_PHRASES  = ["Sai rồi!", "Tôi không gọi cái này!", "Nhầm đơn rồi!"]

const HURRY_THRESHOLD: float = 5.0
const SKIN_TONES  = [Color(1.0, 0.88, 0.73), Color(0.94, 0.76, 0.57), Color(0.82, 0.62, 0.45)]

var desired_order: Dictionary = {}
var max_patience: float = 15.0
var patience: float = 15.0
var patience_drop_rate: float = 1.0
var is_active: bool = true
var _speech_showing: bool = false

@onready var body_rect: ColorRect   = $Body
@onready var head_rect: ColorRect   = $Head
@onready var face_label: Label      = $Head/Face
@onready var hat_label: Label       = $Head/Hat
@onready var type_label: Label      = $TypeLabel
@onready var speech_bubble: Panel   = $SpeechBubble
@onready var speech_label: Label    = $SpeechBubble/SpeechLabel
@onready var patience_bar: ProgressBar = $PatienceBar

func setup(patience_time: float, type: Type = Type.NORMAL) -> void:
	max_patience = patience_time
	patience     = patience_time
	customer_type = type

func _ready() -> void:
	patience_drop_rate = 1.0 + (OrderSystem.current_level - 1) * 0.1
	# Appearance
	if customer_type == Type.NORMAL:
		# Random color for normal customers
		body_rect.color = Color(randf_range(0.2, 0.8), randf_range(0.2, 0.8), randf_range(0.2, 0.8))
	else:
		body_rect.color = TYPE_COLORS[customer_type]

	head_rect.color = SKIN_TONES[randi() % SKIN_TONES.size()]
	
	if customer_type == Type.GRAB:
		hat_label.text = "🧢"
		hat_label.show()
	else:
		hat_label.text = "👒"
		hat_label.visible = (randi() % 4 == 0)

	# Type label
	var t_lbl = TYPE_LABELS[customer_type]
	if t_lbl != "":
		type_label.text = t_lbl
		type_label.show()
	else:
		type_label.hide()

	# Patience bar
	patience_bar.max_value = max_patience
	patience_bar.value     = max_patience

	# Generate order
	desired_order = OrderSystem.generate_order()
	var order_name = desired_order["name"]

	# Slide in from left
	var target_x = position.x
	position.x = target_x - 500
	var tween = create_tween()
	tween.tween_property(self, "position:x", target_x, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished

	# Cart comment first, then order phrase
	await _show_speech(CART_COMMENTS[randi() % CART_COMMENTS.size()])
	await get_tree().create_timer(0.25).timeout

	var arrive = ARRIVE_PHRASES[customer_type]
	var phrase = arrive[randi() % arrive.size()]
	_show_speech(phrase)

func _process(delta: float) -> void:
	if not is_active:
		return
	patience -= delta * patience_drop_rate
	patience_bar.value = patience

	var ratio  = clampf(patience / max_patience, 0.0, 1.0)
	# Clear green → yellow → red gradient
	patience_bar.modulate = Color(1.0, ratio * 0.8 + 0.2, ratio * 0.15)

	if patience <= HURRY_THRESHOLD and patience > HURRY_THRESHOLD - delta:
		if not _speech_showing:
			_show_speech(HURRY_PHRASES[randi() % HURRY_PHRASES.size()])
		face_label.text = ">_<"

	if patience <= 0.0:
		is_active = false
		_leave()

func get_earned(base: int) -> int:
	var ratio = clampf(patience / max_patience, 0.0, 1.0)
	var tip = 0
	if ratio > 0.75: tip = 10
	elif ratio > 0.4: tip = 5
	tip = int(tip * Shop.tip_multiplier)

	var bonus = OrderSystem.get_order_bonus_vnd(desired_order)

	match customer_type:
		Type.GRAB:  return (base + tip + bonus)
		Type.OFFICE:return (base + bonus) + tip + 5
		Type.STUDENT:return (base + bonus) + tip/2 # sinh vien it tien net tip it =))
		_:          return base + tip + bonus

func serve_correct() -> void:
	is_active = false
	face_label.text = "^_^"
	_show_speech(HAPPY_PHRASES[randi() % HAPPY_PHRASES.size()])
	var earned = get_earned(10)
	if is_inside_tree():
		await get_tree().create_timer(1.0).timeout
	customer_served.emit(true, earned)
	_exit_anim()

func serve_wrong() -> void:
	is_active = false
	face_label.text = ">_X"
	_show_speech(WRONG_PHRASES[randi() % WRONG_PHRASES.size()])
	if is_inside_tree():
		await get_tree().create_timer(1.0).timeout
	customer_served.emit(false, 0)
	_exit_anim()

func _leave() -> void:
	face_label.text = "T_T"
	_show_speech(LEAVE_PHRASES[randi() % LEAVE_PHRASES.size()])
	if is_inside_tree():
		await get_tree().create_timer(1.0).timeout
	customer_served.emit(false, 0)
	_exit_anim()

func _exit_anim() -> void:
	var tween = create_tween()
	tween.tween_property(self, "position:x", position.x - 500, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished
	queue_free()

func _show_speech(text: String) -> void:
	_speech_showing = true
	speech_label.text = text
	speech_bubble.show()
	if is_inside_tree():
		await get_tree().create_timer(2.2).timeout
	if is_instance_valid(speech_bubble):
		speech_bubble.hide()
	_speech_showing = false
