extends Node

var bgm_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer

var menu_music = null
var gameplay_music = null
var correct_sfx = null
var wrong_sfx = null

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	
	bgm_player = AudioStreamPlayer.new()
	bgm_player.process_mode = PROCESS_MODE_PAUSABLE # So it stops when paused
	add_child(bgm_player)
	
	sfx_player = AudioStreamPlayer.new()
	sfx_player.process_mode = PROCESS_MODE_ALWAYS # SFX might still play in UI
	add_child(sfx_player)
	
	# Try loading the audio streams safely
	if ResourceLoader.exists("res://audio/menu_music.ogg"):
		menu_music = load("res://audio/menu_music.ogg")
	if ResourceLoader.exists("res://audio/gameplay_music.ogg"):
		gameplay_music = load("res://audio/gameplay_music.ogg")
	if ResourceLoader.exists("res://audio/correct_order.ogg"):
		correct_sfx = load("res://audio/correct_order.ogg")
	if ResourceLoader.exists("res://audio/wrong_order.ogg"):
		wrong_sfx = load("res://audio/wrong_order.ogg")

func play_menu_music() -> void:
	if menu_music and bgm_player.stream != menu_music:
		bgm_player.stream = menu_music
		bgm_player.play()

func play_gameplay_music() -> void:
	if gameplay_music and bgm_player.stream != gameplay_music:
		bgm_player.stream = gameplay_music
		bgm_player.play()

func stop_music() -> void:
	bgm_player.stop()
	bgm_player.stream = null

func play_sfx(success: bool) -> void:
	if success and correct_sfx:
		sfx_player.stream = correct_sfx
		sfx_player.play()
	elif not success and wrong_sfx:
		sfx_player.stream = wrong_sfx
		sfx_player.play()
