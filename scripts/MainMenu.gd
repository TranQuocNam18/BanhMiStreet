extends Control

func _ready() -> void:
	$StartBtn.pressed.connect(_on_start)
	$QuitBtn.pressed.connect(_on_quit)
	# Animate title on hover slightly
	var tween = create_tween().set_loops()
	tween.tween_property($CartDecor, "position:y", $CartDecor.position.y - 8, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property($CartDecor, "position:y", $CartDecor.position.y, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_start() -> void:
	get_tree().change_scene_to_file("res://scenes/GameScene.tscn")

func _on_quit() -> void:
	get_tree().quit()
