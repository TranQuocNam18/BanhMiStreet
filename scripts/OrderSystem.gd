# OrderSystem.gd
# Autoload singleton. Manages order generation, validation, ingredient definitions.

extends Node

# ── Base ingredients (always available) ──────────────────────────────────────
const BASE_INGREDIENTS = ["Bread", "Meat", "Pate", "Vegetables", "TrungOpLa"]

# ── Unlockable ingredients (bought from shop) ─────────────────────────────────
# key: ingredient id, value: { display, emoji, bonus_vnd }
const UNLOCKABLE_INGREDIENTS = {
	"CannedFish": {"display": "Cá Hộp",  "emoji": "🐟", "bonus_vnd": 10},
	"Egg":        {"display": "Trứng",   "emoji": "🥚", "bonus_vnd": 10},
	"GioNhan":    {"display": "Giò Nhân","emoji": "🌭", "bonus_vnd": 15},
}

# ── Drinks (Unlocked by level) ────────────────────────────────────────────────
const DRINKS = {
	"NuocNgot": {"display": "Nước Ngọt", "emoji": "🥤", "bonus_vnd": 5},
	"NuocCam":  {"display": "Nước Cam",  "emoji": "🍹", "bonus_vnd": 10},
	"NuocNho":  {"display": "Nước Nho",  "emoji": "🧃", "bonus_vnd": 15},
	"TraSua":   {"display": "Trà Sữa",   "emoji": "🧋", "bonus_vnd": 20},
}

const NGUYEN_LIEU_THEO_VONG = {
	1: ["NuocNgot"],
	2: ["NuocNgot", "NuocCam"],
	3: ["NuocNgot", "NuocCam", "NuocNho"],
	4: ["NuocNgot", "NuocCam", "NuocNho", "TraSua"]
}

# ── All recipes (filtered at runtime by unlocked ingredients) ─────────────────
const ALL_RECIPES = [
	{"name": "Bánh Mì Thịt",       "ingredients": ["Bread", "Meat"]},
	{"name": "Bánh Mì Đặc Biệt",   "ingredients": ["Bread", "Meat", "Pate"]},
	{"name": "Bánh Mì Chay",        "ingredients": ["Bread", "Vegetables"]},
	{"name": "Bánh Mì Rau Thịt",    "ingredients": ["Bread", "Meat", "Vegetables"]},
	{"name": "Bánh Mì Thập Cẩm",   "ingredients": ["Bread", "Meat", "Pate", "Vegetables"]},
	{"name": "Bánh Mì Pate",        "ingredients": ["Bread", "Pate"]},
	# Unlockable recipes
	{"name": "Bánh Mì Cá Hộp",     "ingredients": ["Bread", "CannedFish"],              "requires": ["CannedFish"]},
	{"name": "Bánh Mì Trứng",       "ingredients": ["Bread", "Egg"],                     "requires": ["Egg"]},
	{"name": "Bánh Mì Giò",         "ingredients": ["Bread", "GioNhan"],                 "requires": ["GioNhan"]},
	{"name": "Bánh Mì Trứng Thịt",  "ingredients": ["Bread", "Egg",    "Meat"],          "requires": ["Egg"]},
	{"name": "Bánh Mì Cá Đặc Biệt","ingredients": ["Bread", "CannedFish", "Vegetables"],"requires": ["CannedFish"]},
	{"name": "Bánh Mì Giò Chả",    "ingredients": ["Bread", "GioNhan", "Pate"],          "requires": ["GioNhan"]},
	{"name": "Bánh Mì Trứng Ốp La", "ingredients": ["Bread", "TrungOpLa"]},
	{"name": "Bánh Mì Thịt Trứng", "ingredients": ["Bread", "Meat", "TrungOpLa"]},
]

# Icons/display for base ingredients
const BASE_INGREDIENT_ICONS = {
	"Bread":      {"display": "Bánh Mì",  "emoji": "🥖"},
	"Meat":       {"display": "Thịt",     "emoji": "🥩"},
	"Pate":       {"display": "Pate",     "emoji": "🟤"},
	"Vegetables": {"display": "Rau",      "emoji": "🥬"},
	"TrungOpLa":  {"display": "Ốp La",    "emoji": "🍳"},
}

# ── Runtime state ─────────────────────────────────────────────────────────────
var money: int = 0
var unlocked_ingredients: Array = []  # List of unlocked ingredient IDs

# ── Levels & Progress ─────────────────────────────────────────────────────────
var current_level: int = 1
var progress: Dictionary = {
	"cap_da_mo": 1,
	"cap_da_hoan_thanh": []
}

func get_all_available() -> Array:
	var base = BASE_INGREDIENTS + unlocked_ingredients
	var lvl = clamp(current_level, 1, 4)
	if NGUYEN_LIEU_THEO_VONG.has(lvl):
		base += NGUYEN_LIEU_THEO_VONG[lvl]
	elif current_level > 4:
		base += NGUYEN_LIEU_THEO_VONG[4]
	return base

func get_ingredient_label(id: String) -> String:
	if BASE_INGREDIENT_ICONS.has(id):
		var d = BASE_INGREDIENT_ICONS[id]
		return d["emoji"] + " " + d["display"]
	if UNLOCKABLE_INGREDIENTS.has(id):
		var d = UNLOCKABLE_INGREDIENTS[id]
		return d["emoji"] + " " + d["display"]
	if DRINKS.has(id):
		var d = DRINKS[id]
		return d["emoji"] + " " + d["display"]
	return id

func generate_order() -> Dictionary:
	# Filter recipes to those whose required ingredients are unlocked
	var valid = []
	for recipe in ALL_RECIPES:
		var ok = true
		if recipe.has("requires"):
			for req in recipe["requires"]:
				if not unlocked_ingredients.has(req):
					ok = false
					break
		if ok:
			valid.append(recipe)
	var chosen = valid[randi() % valid.size()].duplicate(true)
	
	# Randomly add ONE drink from the allowed drinks for this level (~70% chance)
	var lvl = clamp(current_level, 1, 4)
	var available_drinks = NGUYEN_LIEU_THEO_VONG.get(lvl, NGUYEN_LIEU_THEO_VONG[4])
	
	if randf() <= 0.7 and available_drinks.size() > 0:
		var drink = available_drinks[randi() % available_drinks.size()]
		chosen["ingredients"].append(drink)
		chosen["name"] += " + " + DRINKS[drink]["display"]
		
	return chosen

func validate_order(desired: Array, assembled: Array) -> bool:
	if desired.size() != assembled.size():
		return false
	var ds = desired.duplicate(); ds.sort()
	var as_ = assembled.duplicate(); as_.sort()
	return ds == as_

func get_order_bonus_vnd(order: Dictionary) -> int:
	var bonus = 0
	for ing in order.get("ingredients", []):
		if UNLOCKABLE_INGREDIENTS.has(ing):
			bonus += UNLOCKABLE_INGREDIENTS[ing]["bonus_vnd"]
		if DRINKS.has(ing):
			bonus += DRINKS[ing]["bonus_vnd"]
	return bonus

func unlock_ingredient(id: String) -> void:
	if not unlocked_ingredients.has(id):
		unlocked_ingredients.append(id)
