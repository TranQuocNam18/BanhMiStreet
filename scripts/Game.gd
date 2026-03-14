# Game.gd
# Core game state: money, score, round timer, active customer, ingredient assembly.

extends Node2D

const BASE_ROUND_DURATION: float = 360.0   # 6 minutes
const BASE_SPAWN_INTERVAL: float = 9.0

@onready var spawner: Node        = $Spawner
@onready var ui: Control          = $CanvasLayer/UI
@onready var customer_anchor: Node2D = $CustomerAnchor
@onready var shop_panel: Control  = $CanvasLayer/ShopPanel
@onready var round_summary: Control = $CanvasLayer/RoundSummary

# ── State ─────────────────────────────────────────────────────────────────────
var money: int         = 0
var score: int         = 0
var round_number: int  = 0
var customers_failed: int = 0
var round_money_earned: int = 0

var current_ingredients: Array = []
var active_customer: Node2D = null
var _serving: bool = false  # True while customer is exiting (blocks new spawn overlap)

var round_timer_left: float = BASE_ROUND_DURATION
var round_running: bool = false

func _ready() -> void:
	spawner.customer_spawned.connect(_on_customer_spawned)
	ui.ingredient_selected.connect(_on_ingredient_selected)
	ui.undo_pressed.connect(_on_undo_pressed)
	ui.serve_pressed.connect(_on_serve_pressed)
	ui.shop_btn_pressed.connect(_open_shop)

	shop_panel.hide()
	round_summary.hide()

	# Wire shop close button
	var close_btn = shop_panel.get_node_or_null("CloseBtn")
	if close_btn:
		close_btn.pressed.connect(func(): shop_panel.hide())

	# Wire round summary buttons
	var open_shop_btn = round_summary.get_node_or_null("OpenShopBtn")
	if open_shop_btn:
		open_shop_btn.pressed.connect(_open_shop)

	var next_round_btn = round_summary.get_node_or_null("NextRoundBtn")
	if next_round_btn:
		next_round_btn.pressed.connect(func():
			round_summary.hide()
			shop_panel.hide()
			_start_round()
		)

	# Wire menu button
	var menu_btn = ui.get_node_or_null("TopBar/MenuBtn")
	if menu_btn:
		menu_btn.pressed.connect(_on_menu_pressed)

	_start_round()

func _on_menu_pressed() -> void:
	if not is_inside_tree(): return
	spawner.stop()
	Shop.reset_for_new_game()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _start_round() -> void:
	round_number += 1
	round_timer_left = BASE_ROUND_DURATION
	round_money_earned = 0
	score = 0
	customers_failed = 0
	round_running = true

	# Apply difficulty scaling per round
	var patience_scale = max(0.6, 1.0 - (round_number - 1) * 0.08)
	spawner.spawn_interval = max(5.0, BASE_SPAWN_INTERVAL * Shop.spawn_interval_multiplier - (round_number - 1) * 0.5)
	spawner.patience_modifier = Shop.patience_multiplier * patience_scale

	ui.update_round(round_number)
	ui.update_money(money)
	ui.update_score(score)
	ui.update_assembly(current_ingredients)
	ui.hide_order()
	ui.rebuild_ingredient_buttons()

	spawner.start()

func _process(delta: float) -> void:
	if not round_running:
		return
	round_timer_left -= delta
	ui.update_round_timer(round_timer_left)
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
	_show_round_summary()

func _show_round_summary() -> void:
	var summary_lbl: Label = round_summary.get_node("SummaryLabel")
	summary_lbl.text = (
		"🏁 Vòng %d kết thúc!\n\n" % round_number +
		"💰 Tiền kiếm được: %d VND\n" % round_money_earned +
		"✅ Khách phục vụ: %d\n" % score +
		"❌ Khách bỏ đi: %d\n" % customers_failed
	)
	round_summary.show()

func _open_shop() -> void:
	var items_container = shop_panel.get_node("ScrollContainer/ItemsContainer")
	# Clear & rebuild shop cards
	for child in items_container.get_children():
		child.queue_free()
	await get_tree().process_frame  # wait one frame for queue_free

	for item in Shop.CATALOGUE:
		var card = _make_shop_card(item)
		items_container.add_child(card)

	shop_panel.show()

func _make_shop_card(item: Dictionary) -> Control:
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(200, 160)

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
	if Shop.is_owned(item["id"]):
		btn.text = "✅ Đã mua"
		btn.disabled = true
	elif money < item["price"]:
		btn.text = "💸 %d VND" % item["price"]
		btn.disabled = true
	else:
		btn.text = "🛒 Mua %d VND" % item["price"]
		btn.pressed.connect(_on_buy_item.bind(item["id"]))
	vbox.add_child(btn)

	return vbox

func _on_buy_item(item_id: String) -> void:
	var result = Shop.buy_item(item_id, money)
	if result["success"]:
		money -= result["cost"]
		ui.update_money(money)
		ui.rebuild_ingredient_buttons()
		ui.flash_feedback("Đã mua! 🛍️", Color(0.4, 0.8, 1.0))
		# Refresh shop
		_open_shop()

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
	if active_customer == null or not active_customer.is_active:
		return
	var max_ing = 4 + OrderSystem.unlocked_ingredients.size()
	if current_ingredients.size() >= max_ing:
		return
	current_ingredients.append(ingredient)
	ui.update_assembly(current_ingredients)

func _on_undo_pressed() -> void:
	if current_ingredients.size() > 0:
		current_ingredients.pop_back()
		ui.update_assembly(current_ingredients)

func _on_serve_pressed() -> void:
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
		money += earned
		round_money_earned += earned
		score += 1
		ui.update_money(money)
		ui.update_score(score)
		ui.flash_feedback("+%d VND ✓" % earned, Color(0.3, 1.0, 0.4))
	else:
		customers_failed += 1
		ui.flash_feedback("Khách bỏ đi ✗", Color(1.0, 0.35, 0.35))
	ui.hide_order()
	_reset_assembly()

func _reset_assembly() -> void:
	current_ingredients.clear()
	ui.update_assembly(current_ingredients)
