# UI.gd
# Manages all HUD elements. Dynamic ingredient button grid. No duplicate buttons.

extends Control

signal ingredient_selected(ingredient: String)
signal undo_pressed
signal serve_pressed
signal shop_btn_pressed

@onready var money_label: Label           = $TopBar/MoneyLabel
@onready var score_label: Label           = $TopBar/ScoreLabel
@onready var round_label: Label           = $TopBar/RoundLabel
@onready var timer_label: Label           = $TopBar/TimerLabel
@onready var order_panel: Panel           = $OrderPanel
@onready var order_name_lbl: Label        = $OrderPanel/OrderNameLabel
@onready var order_items_lbl: Label       = $OrderPanel/OrderItemsLabel
@onready var assembly_label: Label        = $BottomBar/AssemblyLabel
@onready var feedback_label: Label        = $FeedbackLabel
@onready var serve_btn: Button            = $BottomBar/ServeBtn
@onready var undo_btn: Button             = $BottomBar/UndoBtn
<<<<<<< HEAD
@onready var pause_btn: Button            = $BottomBar/PauseBtn
=======
>>>>>>> 5d32fd774886f6d79ea26af069bfffadaa9e6bcc
@onready var shop_btn: Button             = $TopBar/ShopBtn
@onready var ingredients_grid: GridContainer = $BottomBar/IngredientsGrid

func _ready() -> void:
	serve_btn.pressed.connect(func(): serve_pressed.emit())
	undo_btn.pressed.connect(func(): undo_pressed.emit())
<<<<<<< HEAD
	pause_btn.pressed.connect(toggle_pause)
=======
>>>>>>> 5d32fd774886f6d79ea26af069bfffadaa9e6bcc
	shop_btn.pressed.connect(func(): shop_btn_pressed.emit())
	hide_order()
	feedback_label.hide()
	# Do NOT call rebuild here — Game._start_round() will call it

# ── Ingredient buttons (rebuilt when unlocks change) ──────────────────────────
func rebuild_ingredient_buttons() -> void:
	# Clear existing
	for child in ingredients_grid.get_children():
		child.queue_free()
	
	if not is_inside_tree(): return
	await get_tree().process_frame

	var all_ing = OrderSystem.get_all_available()
	for ing_id in all_ing:
		var label_text = OrderSystem.get_ingredient_label(ing_id)
		var btn = Button.new()
		btn.text = label_text
		btn.custom_minimum_size = Vector2(130, 58)
		btn.add_theme_font_size_override("font_size", 18)
		var id_captured = ing_id
		btn.pressed.connect(func(): ingredient_selected.emit(id_captured))
		ingredients_grid.add_child(btn)

<<<<<<< HEAD
func toggle_pause() -> void:
	var paused = !get_tree().paused
	get_tree().paused = paused
	if paused:
		pause_btn.text = "▶ Chơi"
	else:
		pause_btn.text = "⏸ Dừng"

=======
>>>>>>> 5d32fd774886f6d79ea26af069bfffadaa9e6bcc
# ── HUD ───────────────────────────────────────────────────────────────────────
func update_money(val: int) -> void:
	money_label.text = "💰 %d VND" % val

<<<<<<< HEAD
func update_score(val: int, target: int = 0) -> void:
	if target > 0:
		score_label.text = "✅ %d/%d khách" % [val, target]
	else:
		score_label.text = "✅ %d khách" % val
=======
func update_score(val: int) -> void:
	score_label.text = "✅ %d phục vụ" % val
>>>>>>> 5d32fd774886f6d79ea26af069bfffadaa9e6bcc

func update_round(round_num: int) -> void:
	round_label.text = "Vòng %d" % round_num

func update_round_timer(seconds_left: float) -> void:
	var s  = max(0, int(seconds_left))
	var mm = s / 60
	var ss = s % 60
	timer_label.text = "⏱ %02d:%02d" % [mm, ss]
	if seconds_left <= 30.0:
		timer_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	else:
		timer_label.remove_theme_color_override("font_color")

func show_order(order: Dictionary) -> void:
	order_name_lbl.text = "📋 " + order["name"]
	order_items_lbl.text = ""
	for ing in order["ingredients"]:
		order_items_lbl.text += "• " + OrderSystem.get_ingredient_label(ing) + "\n"
	order_panel.show()

func hide_order() -> void:
	order_panel.hide()

func update_assembly(ingredients: Array) -> void:
	if ingredients.is_empty():
		assembly_label.text = "Chưa có gì..."
	else:
		var parts: Array = []
		for ing in ingredients:
			parts.append(OrderSystem.get_ingredient_label(ing))
		assembly_label.text = " + ".join(parts)

func flash_feedback(text: String, color: Color) -> void:
	feedback_label.text = text
	feedback_label.add_theme_color_override("font_color", color)
	feedback_label.modulate.a = 1.0
	feedback_label.show()
	var tween = create_tween()
	tween.tween_property(feedback_label, "position:y", feedback_label.position.y - 50, 1.0)
	tween.parallel().tween_property(feedback_label, "modulate:a", 0.0, 1.0)
	await tween.finished
	feedback_label.modulate.a = 1.0
	feedback_label.position.y += 50
	feedback_label.hide()
<<<<<<< HEAD

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.is_echo():
		if Input.is_action_just_pressed("pause_game") or event.keycode == KEY_D:
			toggle_pause()
			get_viewport().set_input_as_handled()
		elif Input.is_action_just_pressed("open_shop") or event.keycode == KEY_B:
			shop_btn_pressed.emit()
			get_viewport().set_input_as_handled()
		elif Input.is_action_just_pressed("open_menu") or event.keycode == KEY_M:
			var menu_btn = get_node_or_null("TopBar/MenuBtn")
			if menu_btn:
				menu_btn.pressed.emit()
			get_viewport().set_input_as_handled()
		else:
			match event.keycode:
				KEY_SPACE:
					serve_pressed.emit()
				KEY_W:
					undo_pressed.emit()
=======
>>>>>>> 5d32fd774886f6d79ea26af069bfffadaa9e6bcc
