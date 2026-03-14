extends Control

@onready var tutorial_overlay = $TutorialOverlay
@onready var tutorial_image = $TutorialOverlay/TutorialImage

# ── Tutorial multi-page ──────────────────────────────────────────────────────
var tutorial_pages: Array = [
	"res://assets/tutorial/tutorial_1.png",
	"res://assets/tutorial/tutorial_2.png",
	"res://assets/tutorial/tutorial_3.png",
	"res://assets/tutorial/tutorial_4.png",
]
var current_tutorial_page: int = 0

func _ready() -> void:
	AudioManager.play_menu_music()
	$StartBtn.pressed.connect(func():
		AudioManager.play_sfx("click")
		_on_start()
	)
	$QuitBtn.pressed.connect(func():
		AudioManager.play_sfx("click")
		_on_quit()
	)
	
	# Liên kết nút Hướng Dẫn
	if $TutorialBtn:
		$TutorialBtn.pressed.connect(func():
			AudioManager.play_sfx("click")
			_on_tutorial_pressed()
		)
	if tutorial_overlay and tutorial_overlay.has_node("CloseTutorialBtn"):
		tutorial_overlay.get_node("CloseTutorialBtn").pressed.connect(func():
			AudioManager.play_sfx("click")
			_on_close_tutorial()
		)
	
	# Nút Prev / Next
	var prev_btn = tutorial_overlay.get_node_or_null("PrevBtn")
	var next_btn = tutorial_overlay.get_node_or_null("NextBtn")
	if prev_btn:
		prev_btn.pressed.connect(func():
			AudioManager.play_sfx("click")
			_prev_tutorial_page()
		)
	if next_btn:
		next_btn.pressed.connect(func():
			AudioManager.play_sfx("click")
			_next_tutorial_page()
		)
		
	# Liên kết nút Âm thanh (Loa)
	var sound_btn = get_node_or_null("SoundBtn")
	if sound_btn:
		sound_btn.text = "🔊" if AudioManager.sound_enabled else "🔇"
		sound_btn.pressed.connect(func():
			AudioManager.play_sfx("click")
			AudioManager.toggle_sound()
			sound_btn.text = "🔊" if AudioManager.sound_enabled else "🔇"
		)
		
	# Animate title on hover slightly
	var tween = create_tween().set_loops()
	tween.tween_property($CartDecor, "position:y", $CartDecor.position.y - 8, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property($CartDecor, "position:y", $CartDecor.position.y, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_start() -> void:
	Shop.reset_for_new_game()
	OrderSystem.money = 0
	get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn")

func _on_tutorial_pressed() -> void:
	current_tutorial_page = 0
	_load_tutorial_page()
	tutorial_overlay.show()

func _next_tutorial_page() -> void:
	if current_tutorial_page < tutorial_pages.size() - 1:
		current_tutorial_page += 1
		_load_tutorial_page()

func _prev_tutorial_page() -> void:
	if current_tutorial_page > 0:
		current_tutorial_page -= 1
		_load_tutorial_page()

func _load_tutorial_page() -> void:
	var path = tutorial_pages[current_tutorial_page]
	if ResourceLoader.exists(path):
		tutorial_image.texture = load(path)
	
	# Update page indicator
	var page_label = tutorial_overlay.get_node_or_null("PageLabel")
	if page_label:
		page_label.text = "%d / %d" % [current_tutorial_page + 1, tutorial_pages.size()]
	
	# Update button visibility
	var prev_btn = tutorial_overlay.get_node_or_null("PrevBtn")
	var next_btn = tutorial_overlay.get_node_or_null("NextBtn")
	if prev_btn:
		prev_btn.disabled = (current_tutorial_page == 0)
		prev_btn.modulate.a = 0.4 if current_tutorial_page == 0 else 1.0
	if next_btn:
		next_btn.disabled = (current_tutorial_page >= tutorial_pages.size() - 1)
		next_btn.modulate.a = 0.4 if current_tutorial_page >= tutorial_pages.size() - 1 else 1.0

func _on_close_tutorial() -> void:
	tutorial_overlay.hide()

func _on_quit() -> void:
	get_tree().quit()
