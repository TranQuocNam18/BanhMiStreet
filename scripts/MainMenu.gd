extends Control

func _ready() -> void:
	AudioManager.play_menu_music()
	$StartBtn.pressed.connect(_on_start)
	$QuitBtn.pressed.connect(_on_quit)
	# Animate title on hover slightly
	var tween = create_tween().set_loops()
	tween.tween_property($CartDecor, "position:y", $CartDecor.position.y - 8, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property($CartDecor, "position:y", $CartDecor.position.y, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_start() -> void:
	OrderSystem.money = 0
	get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn")

func _on_quit() -> void:
	get_tree().quit()
