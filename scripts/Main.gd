extends Node

var game_scene = preload("res://scenes/GameScene.tscn")
var current_game = null

func _ready():
	start_game()

func start_game():
	if current_game != null:
		current_game.queue_free()
	current_game = game_scene.instantiate()
	add_child(current_game)
