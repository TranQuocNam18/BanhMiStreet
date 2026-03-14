# Game.gd
# Core game state: money, score, round timer, active customer, ingredient assembly.

extends Node2D

const BASE_ROUND_DURATION: float = 60.0    # 1 minute
const BASE_SPAWN_INTERVAL: float = 9.0

@onready var spawner: Node        = $Spawner
@onready var ui: Control          = $CanvasLayer/UI
@onready var customer_anchor: Node2D = $CustomerAnchor
@onready var shop_panel: Control  = $CanvasLayer/ShopUI
@onready var round_summary: Control = $CanvasLayer/RoundSummary

# ── State ─────────────────────────────────────────────────────────────────────
var score: int         = 0
var round_number: int  = 0
var target_score: int  = 0
var customers_failed: int = 0
var round_money_earned: int = 0

var current_ingredients: Array = []
var active_customer: Node2D = null
var _serving: bool = false  # True while customer is exiting (blocks new spawn overlap)

var round_timer_left: float = BASE_ROUND_DURATION
var round_running: bool = false

func _ready() -> void:
	AudioManager.play_gameplay_music()
	spawner.customer_spawned.connect(_on_customer_spawned)
	ui.ingredient_selected.connect(_on_ingredient_selected)
	ui.undo_pressed.connect(_on_undo_pressed)
	ui.serve_pressed.connect(_on_serve_pressed)
	ui.shop_btn_pressed.connect(_try_toggle_shop)

	shop_panel.hide()
	round_summary.hide()
	shop_panel.z_index = 200  # Đảm bảo cửa hàng hiển thị trên round_summary (z_index=100)
	round_summary.z_index = 100

	# Wire shop close button
	var close_btn = shop_panel.get_node_or_null("ShopCenter/ShopVBox/HeaderHBox/CloseBtn")
	if close_btn:
		close_btn.pressed.connect(func(): 
			AudioManager.play_sfx("click")
			shop_panel.hide()
		)

	# Wire round summary buttons
	var open_shop_btn = round_summary.get_node_or_null("OpenShopBtn")
	if open_shop_btn:
		open_shop_btn.pressed.connect(func():
			AudioManager.play_sfx("click")
			_open_shop()
		)

	var next_round_btn = round_summary.get_node_or_null("NextRoundBtn")
	if next_round_btn:
		next_round_btn.pressed.connect(func():
			AudioManager.play_sfx("click")
			round_summary.hide()
			shop_panel.hide()
			get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn")
		)

	# Wire menu button
	var menu_btn = ui.get_node_or_null("TopBar/HBoxContainer/MenuBtn")
	if menu_btn:
		menu_btn.pressed.connect(_on_menu_pressed)

	_start_round()

func _on_menu_pressed() -> void:
	if not is_inside_tree(): return
	spawner.stop()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _start_round() -> void:
	round_number += 1
	round_timer_left = BASE_ROUND_DURATION
	round_money_earned = 0
	score = 0
	customers_failed = 0
	round_running = true

	# Apply difficulty scaling per round
	var lvl = OrderSystem.current_level
	var patience_scale = max(0.6, 1.0 - (lvl - 1) * 0.08)
	
	# Delay ranges (min, max) for rounds 1, 2, 3, 4+
	var base_delays = [Vector2(4.0, 7.0), Vector2(3.0, 6.0), Vector2(2.0, 5.0), Vector2(1.5, 4.0)]
	var delay_idx = min(lvl - 1, 3)
	var multiplier = Shop.spawn_interval_multiplier
	
	spawner.min_delay = base_delays[delay_idx].x * multiplier
	spawner.max_delay = base_delays[delay_idx].y * multiplier
	spawner.patience_modifier = Shop.patience_multiplier * patience_scale

	# Special Level 6 overrides
	if lvl == 6:
		round_timer_left = 45.0
		spawner.min_delay = 1.0
		spawner.max_delay = 2.5
		patience_scale = 0.5
		spawner.patience_modifier = Shop.patience_multiplier * patience_scale
	
	target_score = lvl + 1
	if lvl == 6:
		target_score = 10

	ui.update_round(lvl)
	ui.update_money(OrderSystem.money) # Uses persistent money
	ui.update_score(score, target_score)
	ui.update_assembly(current_ingredients)
	ui.hide_order()
	ui.rebuild_ingredient_buttons()

	spawner.start()

func _process(delta: float) -> void:
	# Cập nhật nút Cửa Hàng: Mở được nếu đang Dừng (Paused) hoặc Hết Vòng Chơi
	var can_shop = (not round_running) or get_tree().paused
	ui.set_shop_btn_enabled(can_shop)

	if not round_running:
		return
	round_timer_left -= delta
	ui.update_round_timer(round_timer_left)
	
	# Catch-up logic: if round is nearing end or customers served + failed + 1 < target_score
	var total_seen = score + customers_failed + (1 if active_customer != null else 0)
	if total_seen < target_score:
		spawner.is_catch_up = true
	else:
		spawner.is_catch_up = false
		
	if round_timer_left <= 0.0:
		round_running = false
		_end_round()

func _end_round() -> void:
	spawner.stop()
	# Dismiss current customer
	if active_customer != null and is_instance_valid(active_customer):
		active_customer.queue_free()
		active_customer = null
	_reset_assembly()
	ui.hide_order()
	
	# Handle unlocking level
	if score >= target_score:
		if not OrderSystem.progress["cap_da_hoan_thanh"].has(OrderSystem.current_level):
			OrderSystem.progress["cap_da_hoan_thanh"].append(OrderSystem.current_level)
		
		# Unlock next level if the played level is the highest opened
		if OrderSystem.current_level == OrderSystem.progress["cap_da_mo"] and OrderSystem.current_level < 6:
			OrderSystem.progress["cap_da_mo"] += 1
			
		SaveSystem.save_game()
			
	_show_round_summary()

func _show_round_summary() -> void:
	var summary_lbl: Label = round_summary.get_node("SummaryLabel")
	summary_lbl.add_theme_color_override("font_color", Color.WHITE)
	var t = ""
	if OrderSystem.current_level == 6:
		t = "🏁 Cấp Thử Thách kết thúc!\n\n"
	else:
		t = "🏁 Cấp %d kết thúc!\n\n" % OrderSystem.current_level
		
	if score >= target_score:
		t += "🎉 Đã hoàn thành cấp độ!\n"
	else:
		t += "😭 Thất bại (Chưa đủ %d khách)!\n" % target_score
		
	summary_lbl.text = (
		t + "\n"
		+ "💰 Tiền kiếm được: %d VND\n" % round_money_earned
		+ "✅ Khách phục vụ: %d/%d\n" % [score, target_score]
		+ "❌ Khách bỏ đi: %d\n" % customers_failed
	)
	
	var next_round_btn = round_summary.get_node_or_null("NextRoundBtn")
	if next_round_btn:
		if score >= target_score:
			next_round_btn.text = "▶ Cấp Kế Tiếp"
			if OrderSystem.current_level == 6:
				next_round_btn.text = "▶ Hoàn Thành"
			next_round_btn.disabled = false
		else:
			next_round_btn.text = "🔄 Thử Lại"
			# Allow replay
			next_round_btn.disabled = false
			
	round_summary.show()

func _try_toggle_shop() -> void:
	# Nếu trận đấu đang chạy và không bị pause thì ẩn đi/từ chối mở
	if round_running and not get_tree().paused:
		# Gợi ý: có thể không cho cả tắt nếu đang mở (nhưng vốn dĩ shop bị đóng khi _start_round)
		if not shop_panel.visible: 
			return
		
	if shop_panel.visible:
		shop_panel.hide()
	else:
		_open_shop()

func _open_shop() -> void:
	# Đảm bảo cửa hàng nhận tương tác chuột thay vì bị RoundSummary đè lên
	shop_panel.move_to_front()
	
	# Cập nhật thông tin tiền trong shop
	_update_shop_info()
	
	var items_container = shop_panel.get_node("ShopCenter/ShopVBox/ScrollContainer/ItemsContainer")
	# Clear existing items immediately
	for child in items_container.get_children():
		items_container.remove_child(child)
		child.queue_free()
	
	# Small delay to ensure they are gone before rebuilding
	await get_tree().process_frame

	for item in Shop.CATALOGUE:
		var card = _make_shop_card(item)
		items_container.add_child(card)

	shop_panel.show()

func _update_shop_info() -> void:
	var money_lbl = shop_panel.get_node_or_null("ShopCenter/ShopVBox/HeaderHBox/ShopMoneyLabel")
	if money_lbl:
		money_lbl.text = "Tiền: %d VND" % OrderSystem.money
	
	# Reset status label
	var status_lbl = shop_panel.get_node_or_null("ShopCenter/ShopVBox/ShopStatusLabel")
	if status_lbl:
		status_lbl.text = "Chọn vật phẩm để nâng cấp"
		status_lbl.add_theme_color_override("font_color", Color.WHITE)

func _make_shop_card(item: Dictionary) -> Control:
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(220, 170)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	var emoji_lbl = Label.new()
	emoji_lbl.text = item["emoji"]
	emoji_lbl.add_theme_font_size_override("font_size", 36)
	emoji_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(emoji_lbl)

	var name_lbl = Label.new()
	name_lbl.text = item["name"]
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_lbl)

	var desc_lbl = Label.new()
	desc_lbl.text = item["desc"]
	desc_lbl.add_theme_font_size_override("font_size", 13)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(desc_lbl)

	var btn = Button.new()
	btn.process_mode = Node.PROCESS_MODE_ALWAYS
	btn.custom_minimum_size = Vector2(180, 40)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	if Shop.is_owned(item["id"]):
		btn.text = "✅ Đã mua"
		btn.disabled = true
	elif OrderSystem.money < item["price"]:
		btn.text = "💸 %d VND" % item["price"]
		btn.disabled = true
	else:
		btn.text = "🛒 Mua %d VND" % item["price"]
		btn.pressed.connect(_on_buy_button_pressed.bind(item["id"]))
	vbox.add_child(btn)

	return vbox

func _on_buy_button_pressed(item_id: String) -> void:
	AudioManager.play_sfx("click")
	_on_buy_item(item_id)

func _on_buy_item(item_id: String) -> void:
	var status_lbl = shop_panel.get_node_or_null("ShopCenter/ShopVBox/ShopStatusLabel")
	print("Trying to buy: ", item_id, " | Player money: ", OrderSystem.money)
	
	var result = Shop.buy_item(item_id, OrderSystem.money)
	if result["success"]:
		OrderSystem.money -= result["cost"]
		SaveSystem.save_game()
		ui.update_money(OrderSystem.money)
		ui.rebuild_ingredient_buttons()
		
		if status_lbl:
			status_lbl.text = "Đã mua thành công! 🎉"
			status_lbl.add_theme_color_override("font_color", Color.GREEN)
		
		ui.flash_feedback("Đã mua! 🛍️", Color(0.4, 0.8, 1.0))
		
		# If the item unlocked an ingredient, show the recipe popup
		var item = Shop.get_item(item_id)
		if item.has("effect_type") and item["effect_type"] == "unlock_ingredient":
			var unlocked_recipes = OrderSystem.get_recipes_unlocked_by(item["effect_value"])
			if unlocked_recipes.size() > 0:
				ui.show_recipe_unlock(unlocked_recipes)
				shop_panel.hide() # Hide shop to let them see the popup clearly
		else:
			# Refresh shop to update buttons and money label
			_open_shop()
	else:
		var reason = result.get("reason", "Lỗi!")
		print("Fail to buy: ", item_id, " Reason: ", reason)
		
		if status_lbl:
			status_lbl.text = "Lỗi: " + reason
			status_lbl.add_theme_color_override("font_color", Color.RED)
			
		ui.flash_feedback(reason, Color(1.0, 0.3, 0.3))

func _on_customer_spawned(customer: Node2D) -> void:
	if active_customer != null or _serving or not round_running:
		customer.queue_free()
		spawner.can_spawn = false
		if is_inside_tree():
			await get_tree().create_timer(2.0).timeout
		if is_inside_tree():
			spawner.can_spawn = true
		return
	active_customer = customer
	customer_anchor.add_child(customer)
	customer.position = Vector2(0, 0)
	customer.customer_served.connect(_on_customer_served)
	# When customer fully exits the tree, notify spawner
	customer.tree_exited.connect(func():
		spawner.notify_customer_cleared()
		active_customer = null # Clear reference when customer is gone
		_serving = false # Reset serving flag
	)
	ui.show_order(active_customer.desired_order)

func _on_ingredient_selected(ingredient: String) -> void:
	if get_tree().paused: return
	if active_customer == null or not active_customer.is_active:
		return
	var max_ing = 8 # Tăng giới hạn tối đa để có thể chọn nhiều món (Thập cẩm + nước là 5 món)
	if current_ingredients.size() >= max_ing:
		return
	current_ingredients.append(ingredient)
	ui.update_assembly(current_ingredients)

func _on_undo_pressed() -> void:
	if get_tree().paused: return
	if current_ingredients.size() > 0:
		current_ingredients.pop_back()
		ui.update_assembly(current_ingredients)

func _on_serve_pressed() -> void:
	if get_tree().paused: return
	if active_customer == null or not active_customer.is_active:
		return
	if current_ingredients.is_empty():
		return
	var ok = OrderSystem.validate_order(
		active_customer.desired_order["ingredients"], current_ingredients)
	_reset_assembly()
	_serving = true
	var c = active_customer
	active_customer = null
	if ok:
		c.serve_correct()
	else:
		c.serve_wrong()
	ui.hide_order()

func _on_customer_served(success: bool, earned: int) -> void:
	if success:
		OrderSystem.money += earned
		round_money_earned += earned
		score += 1
		SaveSystem.save_game()
		ui.update_money(OrderSystem.money)
		ui.update_score(score, target_score)
		ui.show_earned_money(earned)
	else:
		customers_failed += 1
		ui.flash_feedback("Khách bỏ đi ✗", Color(1.0, 0.35, 0.35))
	ui.hide_order()
	_reset_assembly()

func _reset_assembly() -> void:
	current_ingredients.clear()
	ui.update_assembly(current_ingredients)
