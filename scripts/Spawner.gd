# Spawner.gd
# Spawns customers at regular intervals. One customer at a time via can_spawn flag.

extends Node

signal customer_spawned(customer: Node2D)

<<<<<<< HEAD
@export var min_delay: float = 4.0
@export var max_delay: float = 7.0
=======
@export var spawn_interval: float = 9.0
>>>>>>> 5d32fd774886f6d79ea26af069bfffadaa9e6bcc
@export var customer_scene: PackedScene
var patience_modifier: float = 1.0

var _timer: Timer
var _running: bool = false
var can_spawn: bool = true  # Set to false while a customer is active or exiting
<<<<<<< HEAD
var is_catch_up: bool = false
=======
>>>>>>> 5d32fd774886f6d79ea26af069bfffadaa9e6bcc

func _ready() -> void:
	_timer = Timer.new()
	_timer.autostart = false
	_timer.timeout.connect(_on_timeout)
	add_child(_timer)

func start() -> void:
	_running = true
	can_spawn = true
	if is_inside_tree():
		await get_tree().create_timer(2.0).timeout
	if _running and can_spawn and is_inside_tree():
		_spawn()
<<<<<<< HEAD
		_spawn_next()
=======
		_timer.start(spawn_interval)
>>>>>>> 5d32fd774886f6d79ea26af069bfffadaa9e6bcc

func stop() -> void:
	_running = false
	_timer.stop()

func _on_timeout() -> void:
	if _running:
		if can_spawn: # Check can_spawn here
			_spawn()
<<<<<<< HEAD
		_spawn_next()

func _spawn_next() -> void:
	if not _running: return
	var delay = randf_range(min_delay, max_delay)
	if is_catch_up:
		delay *= 0.6  # Tăng tốc độ nếu đang bị chậm tiến độ
	_timer.start(delay)
=======
>>>>>>> 5d32fd774886f6d79ea26af069bfffadaa9e6bcc

func _spawn() -> void:
	if customer_scene == null:
		push_error("Spawner: customer_scene not set!")
		return
	can_spawn = false # Set to false immediately after passing the can_spawn check
	var c: Node2D = customer_scene.instantiate()
	var base_patience = 15.0 * patience_modifier

	# Weighted random customer type selection
<<<<<<< HEAD
	# 40% NORMAL, 20% GRAB (short patience x0.6), 20% OFFICE, 20% STUDENT
	var roll = randi() % 100
	# Customer.Type enum: NORMAL=0, GRAB=1, OFFICE=2, STUDENT=3
	var ctype = 0
	if roll < 20:
		ctype = 1  # GRAB – shorter patience
		base_patience *= 0.6
	elif roll < 40:
		ctype = 2  # OFFICE - shorter patience 
		base_patience *= 0.8
	elif roll < 60:
		ctype = 3  # STUDENT - normal patience
		base_patience *= 1.1
	else:
		ctype = 0  # NORMAL
=======
	# 70% NORMAL, 15% GRAB (short patience x0.6), 10% BULK, 5% VIP
	var roll = randi() % 100
	# Customer.Type enum: NORMAL=0, GRAB=1, BULK=2, VIP=3
	var ctype = 0
	if roll < 15:
		ctype = 1  # GRAB – shorter patience
		base_patience *= 0.6
	elif roll < 25:
		ctype = 2  # BULK
	elif roll < 30:
		ctype = 3  # VIP – more patient
		base_patience *= 1.4
>>>>>>> 5d32fd774886f6d79ea26af069bfffadaa9e6bcc
	c.setup(base_patience, ctype)
	customer_spawned.emit(c)

func notify_customer_cleared() -> void:
	# Called by Game when the customer slot is free again (after exit anim)
	if is_inside_tree():
		await get_tree().create_timer(1.5).timeout
	if is_inside_tree():
		can_spawn = true
