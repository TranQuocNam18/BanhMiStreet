extends Node

const SAVE_PATH = "user://save_game.save"

func _ready() -> void:
	# Small delay to ensure other autoloads are ready if needed, though being lower in the list is usually enough.
	call_deferred("load_game")

func save_game() -> void:
	var save_dict = {
		"money": OrderSystem.money,
		"unlocked_ingredients": OrderSystem.unlocked_ingredients,
		"owned_items": Shop.owned_items,
		"patience_multiplier": Shop.patience_multiplier,
		"spawn_interval_multiplier": Shop.spawn_interval_multiplier,
		"tip_multiplier": Shop.tip_multiplier,
		"current_level": OrderSystem.current_level,
		"progress": OrderSystem.progress
	}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(save_dict)
		file.close()
		print("Game saved!")

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		print("No save file found.")
		return
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var data = file.get_var()
		if typeof(data) == TYPE_DICTIONARY:
			if data.has("money"): OrderSystem.money = data["money"]
			if data.has("unlocked_ingredients"): OrderSystem.unlocked_ingredients = data["unlocked_ingredients"]
			if data.has("owned_items"): Shop.owned_items = data["owned_items"]
			if data.has("patience_multiplier"): Shop.patience_multiplier = data["patience_multiplier"]
			if data.has("spawn_interval_multiplier"): Shop.spawn_interval_multiplier = data["spawn_interval_multiplier"]
			if data.has("tip_multiplier"): Shop.tip_multiplier = data["tip_multiplier"]
			if data.has("current_level"): OrderSystem.current_level = data["current_level"]
			if data.has("progress"): OrderSystem.progress = data["progress"]
			print("Game loaded!")
		file.close()

func reset_save() -> void:
	OrderSystem.money = 0
	OrderSystem.unlocked_ingredients.clear()
	OrderSystem.current_level = 1
	OrderSystem.progress = { "cap_da_mo": 1, "cap_da_hoan_thanh": [] }
	Shop.owned_items.clear()
	Shop.patience_multiplier = 1.0
	Shop.spawn_interval_multiplier = 1.0
	Shop.tip_multiplier = 1.0
	save_game()
