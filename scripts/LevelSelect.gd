extends Control

const TOTAL_LEVELS = 6

@onready var grid: GridContainer = $CenterContainer/GridContainer
@onready var back_btn: Button = $BackBtn

func _ready() -> void:
	AudioManager.play_menu_music()
	back_btn.pressed.connect(func(): 
		AudioManager.play_sfx("click")
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
	
	for i in range(1, TOTAL_LEVELS + 1):
		var btn = _create_level_btn(i)
		grid.add_child(btn)

func _create_level_btn(level_num: int) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(160, 160)
	
	var is_unlocked = level_num <= OrderSystem.progress["cap_da_mo"]
	var is_completed = OrderSystem.progress["cap_da_hoan_thanh"].has(level_num)
	
	if is_unlocked:
		var text = "Cấp %d" % level_num
		if level_num == 6:
			text = "Cấp 6\nThử Thách"
		if is_completed:
			text += "\n✓"
		btn.text = text
		btn.add_theme_color_override("font_color", Color(1, 1, 0.8))
		btn.add_theme_font_size_override("font_size", 28)
		btn.pressed.connect(func():
			AudioManager.play_sfx("click")
			_on_level_selected(level_num)
		)
	else:
		if level_num == 6:
			btn.text = "Cấp 6\n🔒\nThử Thách"
		else:
			btn.text = "Cấp %d\n🔒" % level_num
		btn.disabled = true
		btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		btn.add_theme_font_size_override("font_size", 24)
		
	return btn

func _on_level_selected(level_num: int) -> void:
	OrderSystem.current_level = level_num
	AudioManager.stop_music()
	get_tree().change_scene_to_file("res://scenes/GameScene.tscn")
