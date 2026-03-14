# Shop.gd
# Data and logic for the in-game Vietnamese item shop.

extends Node

signal item_purchased(item_id: String)

# ── Shop catalogue ─────────────────────────────────────────────────────────────
# Each item: id, name_vn, emoji, price, description, effect_type, effect_value
# effect_type: "patience_multiplier" | "unlock_ingredient" | "tip_multiplier" | "spawn_speed"
const CATALOGUE = [
	{
		"id": "ice_bucket",
		"name": "Thau Đá",
		"emoji": "🧊",
		"price": 200000,
		"desc": "Đá lạnh giúp khách chờ lâu hơn!\n+30% thời gian kiên nhẫn",
		"effect_type": "patience_multiplier",
		"effect_value": 1.30,
	},
	{
		"id": "shade_cover",
		"name": "Mica Che Nắng",
		"emoji": "☂️",
		"price": 220000,
		"desc": "Khách thích đến hơn!\n+1 khách mỗi vòng",
		"effect_type": "spawn_speed",
		"effect_value": 0.85,  # multiplier on spawn interval
	},
	{
		"id": "cassette",
		"name": "Đài Cassette",
		"emoji": "📻",
		"price": 260000,
		"desc": "Nhạc vui, khách hào phóng!\nTiền tip x2",
		"effect_type": "tip_multiplier",
		"effect_value": 2.0,
	},
	{
		"id": "unlock_fish",
		"name": "Cá Hộp",
		"emoji": "🐟",
		"price": 120000,
		"desc": "Mở khóa nguyên liệu Cá Hộp.\n",
		"effect_type": "unlock_ingredient",
		"effect_value": "CannedFish",
	},
	{
		"id": "unlock_egg",
		"name": "Trứng",
		"emoji": "🥚",
		"price": 150000,
		"desc": "Mở khóa nguyên liệu Trứng.\n",
		"effect_type": "unlock_ingredient",
		"effect_value": "Egg",
	},
	{
		"id": "unlock_gio",
		"name": "Giò Nhân",
		"emoji": "🌭",
		"price": 180000,
		"desc": "Mở khóa Giò Nhân cao cấp!\n",
		"effect_type": "unlock_ingredient",
		"effect_value": "GioNhan",
	},
]

var owned_items: Array = []

# Active effect values (adjusted as items are purchased)
var patience_multiplier: float = 1.0
var spawn_interval_multiplier: float = 1.0
var tip_multiplier: float = 1.0

func buy_item(item_id: String, player_money: int) -> Dictionary:
	var item = get_item(item_id)
	if item.is_empty():
		return {"success": false, "reason": "Không tìm thấy vật phẩm"}
	if owned_items.has(item_id):
		return {"success": false, "reason": "Đã sở hữu"}
	if player_money < item["price"]:
		return {"success": false, "reason": "Không đủ tiền!"}

	owned_items.append(item_id)
	_apply_effect(item)
	item_purchased.emit(item_id)
	return {"success": true, "cost": item["price"]}

func _apply_effect(item: Dictionary) -> void:
	match item["effect_type"]:
		"patience_multiplier":
			patience_multiplier *= item["effect_value"]
		"spawn_speed":
			spawn_interval_multiplier *= item["effect_value"]
		"tip_multiplier":
			tip_multiplier *= item["effect_value"]
		"unlock_ingredient":
			OrderSystem.unlock_ingredient(item["effect_value"])

func get_item(item_id: String) -> Dictionary:
	for item in CATALOGUE:
		if item["id"] == item_id:
			return item
	return {}

func is_owned(item_id: String) -> bool:
	return owned_items.has(item_id)

func reset_for_new_game() -> void:
	owned_items.clear()
	patience_multiplier = 1.0
	spawn_interval_multiplier = 1.0
	tip_multiplier = 1.0
	OrderSystem.unlocked_ingredients.clear()
