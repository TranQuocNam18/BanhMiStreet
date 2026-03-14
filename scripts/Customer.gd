# Customer.gd
# Handles patience, Vietnamese phrases, cart comments, customer TYPES, and animations.
# Uses chibi character sprites loaded at runtime.

extends Node2D

signal customer_served(success: bool, earned: int)

# ── Customer Types ────────────────────────────────────────────────────────────
enum Type { NORMAL, GRAB, OFFICE, STUDENT }

var customer_type: Type = Type.NORMAL

const TYPE_LABELS = {
	Type.NORMAL: "",
	Type.GRAB:   "🛵 GRAB",
	Type.OFFICE: "👔 Văn Phòng",
	Type.STUDENT:"🎒 Học Sinh",
}

# ── Sprite paths per type ─────────────────────────────────────────────────────
const NORMAL_SPRITES = [
	"res://assets/characters/customer_normal_1.png",
	"res://assets/characters/customer_normal_2.png",
	"res://assets/characters/customer_normal_3.png",
]
const TYPE_SPRITES = {
	Type.GRAB:    "res://assets/characters/customer_grab.png",
	Type.OFFICE:  "res://assets/characters/customer_office.png",
	Type.STUDENT: "res://assets/characters/customer_student.png",
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

var desired_order: Dictionary = {}
var max_patience: float = 15.0
var patience: float = 15.0
var patience_drop_rate: float = 1.0
var is_active: bool = true
var _speech_showing: bool = false
var _idle_tween: Tween = null

@onready var character_sprite: TextureRect = $CharacterSprite
@onready var type_label: Label       = $TypeLabel
@onready var speech_bubble: Panel    = $SpeechBubble
@onready var speech_label: Label     = $SpeechBubble/SpeechLabel
@onready var patience_bar: ProgressBar = $PatienceBar
@onready var emoji_reaction: Label   = $EmojiReaction

func setup(patience_time: float, type: Type = Type.NORMAL) -> void:
	max_patience = patience_time
	patience     = patience_time
	customer_type = type

func _ready() -> void:
	patience_drop_rate = 1.0 + (OrderSystem.current_level - 1) * 0.1
	
	# Load character sprite
	_load_sprite()

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

	# Slide in from left
	var target_x = position.x
	position.x = target_x - 500
	var tween = create_tween()
	tween.tween_property(self, "position:x", target_x, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	AudioManager.play_sfx("customer_arrive")
	await tween.finished

	# Start idle animation
	_start_idle_anim()

	# Cart comment first, then order phrase
	await _show_speech(CART_COMMENTS[randi() % CART_COMMENTS.size()])
	await get_tree().create_timer(0.25).timeout

	var arrive = ARRIVE_PHRASES[customer_type]
	var phrase = arrive[randi() % arrive.size()]
	_show_speech(phrase)

func _load_sprite() -> void:
	var path: String
	if customer_type == Type.NORMAL:
		path = NORMAL_SPRITES[randi() % NORMAL_SPRITES.size()]
	else:
		path = TYPE_SPRITES[customer_type]
	
	if ResourceLoader.exists(path):
		character_sprite.texture = load(path)

func _start_idle_anim() -> void:
	if _idle_tween and _idle_tween.is_valid():
		_idle_tween.kill()
	_idle_tween = create_tween().set_loops()
	_idle_tween.tween_property(self, "position:y", position.y - 4, 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_idle_tween.tween_property(self, "position:y", position.y + 4, 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _show_emoji(emoji: String) -> void:
	if not is_instance_valid(emoji_reaction):
		return
	emoji_reaction.text = emoji
	emoji_reaction.modulate.a = 1.0
	emoji_reaction.show()
	var base_y = emoji_reaction.position.y
	var t = create_tween()
	t.tween_property(emoji_reaction, "position:y", base_y - 40, 0.8).set_trans(Tween.TRANS_SINE)
	t.parallel().tween_property(emoji_reaction, "modulate:a", 0.0, 0.8)
	await t.finished
	if is_instance_valid(emoji_reaction):
		emoji_reaction.hide()
		emoji_reaction.position.y = base_y
		emoji_reaction.modulate.a = 1.0

func _process(delta: float) -> void:
	if not is_active:
		return
	patience -= delta * patience_drop_rate
	patience_bar.value = patience

	var ratio  = clampf(patience / max_patience, 0.0, 1.0)
	# Green → yellow → red gradient
	patience_bar.modulate = Color(1.0, ratio * 0.8 + 0.2, ratio * 0.15)

	if patience <= HURRY_THRESHOLD and patience > HURRY_THRESHOLD - delta:
		if not _speech_showing:
			_show_speech(HURRY_PHRASES[randi() % HURRY_PHRASES.size()])
		# Flash sprite red briefly
		character_sprite.modulate = Color(1.2, 0.8, 0.8, 1.0)
		_show_emoji("😤")

	if patience <= 0.0:
		is_active = false
		_leave()

func get_earned(base: int = 0) -> int:
	var ratio = clampf(patience / max_patience, 0.0, 1.0)
	var base_order_price = OrderSystem.get_order_price(desired_order)
	
	var tip_percent = 0.0
	if ratio > 0.75: tip_percent = 0.15
	elif ratio > 0.4: tip_percent = 0.05
	
	var tip = int(base_order_price * tip_percent * Shop.tip_multiplier)

	match customer_type:
		Type.GRAB:   return base_order_price + tip
		Type.OFFICE: return base_order_price + tip + 5000
		Type.STUDENT:return base_order_price + int(tip/2.0)
		_:           return base_order_price + tip

func serve_correct() -> void:
	is_active = false
	_kill_animations()
	character_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
	AudioManager.play_sfx("money")
	_show_emoji("😍")
	
	# Happy bounce
	var t = create_tween()
	t.tween_property(character_sprite, "scale", Vector2(1.1, 0.9), 0.1)
	t.tween_property(character_sprite, "scale", Vector2(0.95, 1.05), 0.1)
	t.tween_property(character_sprite, "scale", Vector2(1.0, 1.0), 0.1)
	
	if is_inside_tree():
		await get_tree().create_timer(0.4).timeout
	AudioManager.play_sfx("customer_leave")
	
	_show_speech(HAPPY_PHRASES[randi() % HAPPY_PHRASES.size()])
	var earned = get_earned(10)
	if is_inside_tree():
		await get_tree().create_timer(1.0).timeout
	customer_served.emit(true, earned)
	_exit_anim()

func serve_wrong() -> void:
	is_active = false
	_kill_animations()
	character_sprite.modulate = Color(1.0, 0.7, 0.7, 1.0)
	AudioManager.play_sfx("xin_loi")
	_show_emoji("😠")
	
	# Shake animation
	var t = create_tween()
	for i in 3:
		t.tween_property(character_sprite, "position:x", character_sprite.position.x + 5, 0.05)
		t.tween_property(character_sprite, "position:x", character_sprite.position.x - 5, 0.05)
	t.tween_property(character_sprite, "position:x", character_sprite.position.x, 0.05)
	
	_show_speech(WRONG_PHRASES[randi() % WRONG_PHRASES.size()])
	if is_inside_tree():
		await get_tree().create_timer(1.0).timeout
	customer_served.emit(false, 0)
	_exit_anim()

func _leave() -> void:
	_kill_animations()
	character_sprite.modulate = Color(0.8, 0.8, 0.9, 1.0)
	AudioManager.play_sfx("xin_loi")
	_show_emoji("😢")
	_show_speech(LEAVE_PHRASES[randi() % LEAVE_PHRASES.size()])
	if is_inside_tree():
		await get_tree().create_timer(1.0).timeout
	customer_served.emit(false, 0)
	_exit_anim()

func _kill_animations() -> void:
	if _idle_tween and _idle_tween.is_valid():
		_idle_tween.kill()

func _exit_anim() -> void:
	var tween = create_tween()
	tween.tween_property(self, "position:x", position.x - 500, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.35)
	await tween.finished
	queue_free()

func _show_speech(text: String) -> void:
	_speech_showing = true
	speech_label.text = text
	
	speech_bubble.modulate.a = 0.0
	speech_bubble.show()
	var t = create_tween()
	t.tween_property(speech_bubble, "modulate:a", 1.0, 0.15)
	
	if is_inside_tree():
		await get_tree().create_timer(2.2).timeout
	if is_instance_valid(speech_bubble):
		var t2 = create_tween()
		t2.tween_property(speech_bubble, "modulate:a", 0.0, 0.15)
		await t2.finished
		if is_instance_valid(speech_bubble):
			speech_bubble.hide()
			speech_bubble.modulate.a = 1.0
	_speech_showing = false
