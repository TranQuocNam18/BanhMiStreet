# UI.gd
# Manages all HUD elements. Dynamic ingredient button grid. No duplicate buttons.

extends Control

signal ingredient_selected(ingredient: String)
signal undo_pressed
signal serve_pressed
signal shop_btn_pressed

@onready var money_label: Label           = $TopBar/HBoxContainer/MoneyVBox/MoneyLabel
@onready var earned_money_label: Label    = $TopBar/EarnedMoneyLabel
@onready var score_label: Label           = $TopBar/HBoxContainer/ScoreLabel
@onready var round_label: Label           = $TopBar/HBoxContainer/RoundLabel
@onready var timer_label: Label           = $TopBar/HBoxContainer/TimerLabel
@onready var order_panel: Panel           = $OrderPanel
@onready var order_name_lbl: Label        = $OrderPanel/OrderNameLabel
@onready var order_items_lbl: Label       = $OrderPanel/OrderItemsLabel
@onready var assembly_label: Label        = $BottomBar/AssemblyLabel
@onready var feedback_label: Label        = $FeedbackLabel
@onready var countdown_label: Label       = $CountdownLabel
@onready var serve_btn: Button            = $BottomBar/ServeBtn
@onready var undo_btn: Button             = $BottomBar/UndoBtn
@onready var pause_btn: Button            = $BottomBar/PauseBtn
@onready var menu_btn: Button             = $TopBar/HBoxContainer/MenuBtn
@onready var shop_btn: Button             = $TopBar/HBoxContainer/ShopBtn
@onready var ingredients_grid: GridContainer = $BottomBar/IngredientsGrid
@onready var bottom_bar: Panel              = $BottomBar
@onready var cart_glass: ColorRect           = $BottomBar/CartGlass
@onready var cart_glass_frame: ReferenceRect = $BottomBar/CartGlassFrame
@onready var cart_light: ColorRect           = $BottomBar/CartLight
@onready var cart_shadow: ColorRect          = $BottomBar/CartShadow

@onready var recipe_unlock_popup: Control = $RecipeUnlockPopup
@onready var recipe_unlock_list: VBoxContainer = $RecipeUnlockPopup/Panel/VBoxContainer/ScrollContainer/RecipesList
@onready var recipe_unlock_close: Button = $RecipeUnlockPopup/Panel/VBoxContainer/CloseBtn

func _ready() -> void:
	serve_btn.pressed.connect(func(): 
		AudioManager.play_sfx("click")
		serve_pressed.emit()
	)
	undo_btn.pressed.connect(func(): 
		AudioManager.play_sfx("click")
		undo_pressed.emit()
	)
	pause_btn.pressed.connect(func():
		AudioManager.play_sfx("click")
		toggle_pause()
	)
	shop_btn.pressed.connect(func(): 
		AudioManager.play_sfx("click")
		shop_btn_pressed.emit()
	)
	
	var sound_btn = get_node_or_null("TopBar/HBoxContainer/SoundBtn")
	if sound_btn:
		sound_btn.text = "🔊" if AudioManager.sound_enabled else "🔇"
		sound_btn.pressed.connect(func():
			AudioManager.play_sfx("click")
			AudioManager.toggle_sound()
			sound_btn.text = "🔊" if AudioManager.sound_enabled else "🔇"
		)
		
	recipe_unlock_close.pressed.connect(func():
		AudioManager.play_sfx("click")
		recipe_unlock_popup.hide()
	)
		
	hide_order()
	feedback_label.hide()
	countdown_label.hide()
	recipe_unlock_popup.hide()
	recipe_unlock_popup.z_index = 250 # Ensure it shows above RoundSummary (and ShopUI)

# ── Ingredient buttons (rebuilt when unlocks change) ──────────────────────────
func _make_btn_stylebox(bg_color: Color, border_color: Color) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = border_color
	sb.corner_radius_top_left = 12
	sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_right = 12
	sb.corner_radius_bottom_left = 12
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	sb.shadow_color = Color(0, 0, 0, 0.3)
	sb.shadow_size = 3
	sb.shadow_offset = Vector2(1, 2)
	return sb

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
		btn.custom_minimum_size = Vector2(130, 52)
		btn.add_theme_font_size_override("font_size", 17)
		btn.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7, 1.0))
		btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 0.9, 1.0))
		
		# Normal style
		var normal_sb = _make_btn_stylebox(
			Color(0.18, 0.1, 0.04, 0.95),
			Color(0.85, 0.65, 0.2, 0.9)
		)
		btn.add_theme_stylebox_override("normal", normal_sb)
		
		# Hover style
		var hover_sb = _make_btn_stylebox(
			Color(0.28, 0.16, 0.06, 0.98),
			Color(1.0, 0.85, 0.3, 1.0)
		)
		btn.add_theme_stylebox_override("hover", hover_sb)
		
		# Pressed style
		var pressed_sb = _make_btn_stylebox(
			Color(0.35, 0.2, 0.05, 1.0),
			Color(1.0, 0.9, 0.4, 1.0)
		)
		btn.add_theme_stylebox_override("pressed", pressed_sb)
		
		var id_captured = ing_id
		btn.pressed.connect(func(): 
			AudioManager.play_sfx("click")
			ingredient_selected.emit(id_captured)
		)
		ingredients_grid.add_child(btn)
	# Wait a frame for layout, then resize containers to fit
	await get_tree().process_frame
	_resize_ingredient_area()

func _resize_ingredient_area() -> void:
	# Use actual rendered grid height instead of estimate
	var grid_height = ingredients_grid.get_combined_minimum_size().y
	if grid_height < 52:
		grid_height = 52
	
	# Layout from bottom up within BottomBar
	var content_bottom = 210   # near BottomBar bottom edge
	var grid_bottom = content_bottom
	var grid_top = grid_bottom - grid_height
	var assembly_bottom = grid_top - 6
	var assembly_top = assembly_bottom - 26
	var glass_top = assembly_top - 4
	var glass_bottom = content_bottom + 2
	
	# Update positions
	ingredients_grid.offset_top = grid_top
	ingredients_grid.offset_bottom = grid_bottom
	assembly_label.offset_top = assembly_top
	assembly_label.offset_bottom = assembly_bottom
	cart_glass.offset_top = glass_top
	cart_glass.offset_bottom = glass_bottom
	cart_glass_frame.offset_top = glass_top
	cart_glass_frame.offset_bottom = glass_bottom
	cart_light.offset_top = glass_top
	cart_light.offset_bottom = glass_top + 20
	
	# Expand BottomBar upward if content doesn't fit
	var needed_height = glass_bottom + 10
	if needed_height > 225:
		bottom_bar.offset_top = -needed_height
	else:
		bottom_bar.offset_top = -225
	
	# Keep shadow at the bottom edge
	cart_shadow.offset_top = needed_height - 15
	cart_shadow.offset_bottom = needed_height + 5

func toggle_pause() -> void:
	var paused = !get_tree().paused
	get_tree().paused = paused
		
	if paused:
		pause_btn.text = "▶ Chơi"
	else:
		pause_btn.text = "⏸ Dừng"
		
	# Disable gameplay buttons while paused
	serve_btn.disabled = paused
	undo_btn.disabled = paused
	for child in ingredients_grid.get_children():
		if child is Button:
			child.disabled = paused
			
	if paused:
		set_shop_btn_enabled(true)

func set_shop_btn_enabled(enabled: bool) -> void:
	if enabled:
		shop_btn.modulate.a = 1.0
		shop_btn.tooltip_text = ""
	else:
		shop_btn.modulate.a = 0.5
		shop_btn.tooltip_text = "Chỉ mở cửa hàng khi kết thúc phục vụ hoặc khi dừng game."

# ── HUD ───────────────────────────────────────────────────────────────────────
func update_money(val: int) -> void:
	money_label.text = "💰 %d VND" % val

func show_earned_money(amount: int) -> void:
	earned_money_label.text = "+%d VND" % amount
	earned_money_label.show()
	var tween = create_tween()
	tween.tween_interval(1.2)
	tween.tween_property(earned_money_label, "modulate:a", 0.0, 0.3)
	await tween.finished
	earned_money_label.hide()
	earned_money_label.modulate.a = 1.0

func update_score(val: int, target: int = 0) -> void:
	if target > 0:
		score_label.text = "✅ %d/%d khách" % [val, target]
	else:
		score_label.text = "✅ %d khách" % val

func update_round(round_num: int) -> void:
	round_label.text = "Vòng %d" % round_num

var _countdown_tween: Tween = null

func update_round_timer(seconds_left: float) -> void:
	var s  = max(0, int(seconds_left))
	var mm = s / 60
	var ss = s % 60
	timer_label.text = "⏱ %02d:%02d" % [mm, ss]
	if seconds_left <= 30.0:
		timer_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	else:
		timer_label.remove_theme_color_override("font_color")
	
	# Countdown overlay for last 5 seconds
	if seconds_left <= 5.0 and seconds_left > 0.0:
		var display_num = ceili(seconds_left)
		countdown_label.text = str(display_num)
		if not countdown_label.visible:
			countdown_label.show()
		# Pulse animation on each new second
		var new_sec = ceili(seconds_left)
		var prev_sec = ceili(seconds_left + get_process_delta_time())
		if new_sec != prev_sec or not countdown_label.visible:
			if _countdown_tween and _countdown_tween.is_valid():
				_countdown_tween.kill()
			countdown_label.scale = Vector2(1.5, 1.5)
			countdown_label.modulate.a = 1.0
			_countdown_tween = create_tween()
			_countdown_tween.tween_property(countdown_label, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			_countdown_tween.parallel().tween_property(countdown_label, "modulate:a", 0.7, 0.8)
	elif seconds_left <= 0.0:
		countdown_label.hide()
	else:
		if countdown_label.visible:
			countdown_label.hide()

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

func show_recipe_unlock(recipes: Array) -> void:
	# Clear old list
	for child in recipe_unlock_list.get_children():
		child.queue_free()
		
	for recipe in recipes:
		var lbl = Label.new()
		var ing_names = []
		for ing in recipe["ingredients"]:
			ing_names.append(OrderSystem.get_ingredient_label(ing))
		lbl.text = "• %s: %s" % [recipe["name"], ", ".join(ing_names)]
		lbl.add_theme_font_size_override("font_size", 20)
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		recipe_unlock_list.add_child(lbl)
		
	# Move popup to CanvasLayer so it sits correctly on top of ShopUI & RoundSummary
	var canvas = get_parent()
	if canvas and recipe_unlock_popup.get_parent() != canvas:
		recipe_unlock_popup.get_parent().remove_child(recipe_unlock_popup)
		canvas.add_child(recipe_unlock_popup)
	else:
		canvas.move_child(recipe_unlock_popup, -1)
	
	recipe_unlock_popup.show()

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

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.is_echo():
		var viewport = get_viewport()
		
		# Chức năng: Tạm dừng
		if Input.is_action_just_pressed("pause_game") or event.keycode == KEY_D:
			toggle_pause()
			if viewport: viewport.set_input_as_handled()
			
		# Chức năng: Mở/Đóng cửa hàng
		elif Input.is_action_just_pressed("open_shop") or event.keycode == KEY_B:
			shop_btn_pressed.emit()
			if viewport: viewport.set_input_as_handled()
			
		# Chức năng: Về menu chính (Cho phép bấm M kể cả khi Pause)
		elif Input.is_action_just_pressed("open_menu") or event.keycode == KEY_M:
			if menu_btn:
				menu_btn.pressed.emit()
			# Chỉ đánh dấu đã xử lý nếu viewport vẫn còn tồn tại (vì pressed.emit() có thể đã xóa cảnh)
			if is_inside_tree() and get_viewport(): 
				get_viewport().set_input_as_handled()
		elif not get_tree().paused: # Block serving/undoing using keyboard while paused
			match event.keycode:
				KEY_SPACE:
					serve_pressed.emit()
				KEY_W:
					undo_pressed.emit()
