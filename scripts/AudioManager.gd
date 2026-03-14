extends Node

var bgm_player: AudioStreamPlayer

var sound_enabled: bool = true

# Music Tracks
var menu_music = preload("res://audio/music/bgm_menu.ogg")
var gameplay_music = preload("res://audio/music/bgm_gameplay.ogg")

# SFX Dictionary
var sfx_dict = {
	"click": preload("res://audio/sfx/sfx_click.wav"),
	"customer_arrive": preload("res://audio/sfx/sfx_customer_arrive.wav"),
	"customer_leave": preload("res://audio/sfx/sfx_customer_leave.wav"),
	"money": preload("res://audio/sfx/sfx_money.wav"),
	"xin_loi": preload("res://audio/sfx/xin_loi_quy_khach_5e480b82-64f2-466c-ac73-a32b9b8304b5.wav")
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = "Music"
	bgm_player.process_mode = Node.PROCESS_MODE_PAUSABLE # Stop naturally if Game is paused
	add_child(bgm_player)

func play_menu_music() -> void:
	if not sound_enabled: return
	bgm_player.volume_db = -2.0
	if bgm_player.stream != menu_music:
		bgm_player.stream = menu_music
		bgm_player.play()

func play_gameplay_music() -> void:
	if not sound_enabled: return
	bgm_player.volume_db = -10.0
	if bgm_player.stream != gameplay_music:
		bgm_player.stream = gameplay_music
		bgm_player.play()

func stop_music() -> void:
	bgm_player.stop()
	bgm_player.stream = null

func play_sfx(sound_name: String) -> void:
	if not sound_enabled: return
	if sfx_dict.has(sound_name):
		var p = AudioStreamPlayer.new()
		p.stream = sfx_dict[sound_name]
		p.bus = "SFX"
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(p)
		p.play()
		p.finished.connect(p.queue_free)
	else:
		push_warning("AudioManager: Không tìm thấy SFX tên: " + sound_name)

func toggle_sound() -> void:
	sound_enabled = !sound_enabled
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), not sound_enabled)
	
	if not sound_enabled:
		stop_music()
	else:
		var current_scene = get_tree().current_scene
		if current_scene:
			if current_scene.name == "MainMenu" or current_scene.name == "LevelSelect":
				play_menu_music()
			elif current_scene.name == "GameScene":
				play_gameplay_music()
