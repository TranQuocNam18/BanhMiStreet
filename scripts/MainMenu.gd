extends Control

func _ready() -> void:
<<<<<<< HEAD
	AudioManager.play_menu_music()
=======
>>>>>>> 5d32fd774886f6d79ea26af069bfffadaa9e6bcc
	$StartBtn.pressed.connect(_on_start)
	$QuitBtn.pressed.connect(_on_quit)
	# Animate title on hover slightly
	var tween = create_tween().set_loops()
	tween.tween_property($CartDecor, "position:y", $CartDecor.position.y - 8, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property($CartDecor, "position:y", $CartDecor.position.y, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_start() -> void:
<<<<<<< HEAD
	OrderSystem.money = 0
	get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn")
=======
	get_tree().change_scene_to_file("res://scenes/GameScene.tscn")
>>>>>>> 5d32fd774886f6d79ea26af069bfffadaa9e6bcc

func _on_quit() -> void:
	get_tree().quit()
