# Spawner.gd
# Spawns customers at regular intervals. One customer at a time via can_spawn flag.

extends Node

signal customer_spawned(customer: Node2D)

@export var spawn_interval: float = 9.0
@export var customer_scene: PackedScene
var patience_modifier: float = 1.0

var _timer: Timer
var _running: bool = false
var can_spawn: bool = true  # Set to false while a customer is active or exiting

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
		_timer.start(spawn_interval)

func stop() -> void:
	_running = false
	_timer.stop()

func _on_timeout() -> void:
	if _running:
		if can_spawn: # Check can_spawn here
			_spawn()

func _spawn() -> void:
	if customer_scene == null:
		push_error("Spawner: customer_scene not set!")
		return
	can_spawn = false # Set to false immediately after passing the can_spawn check
	var c: Node2D = customer_scene.instantiate()
	var base_patience = 15.0 * patience_modifier

	# Weighted random customer type selection
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
	c.setup(base_patience, ctype)
	customer_spawned.emit(c)

func notify_customer_cleared() -> void:
	# Called by Game when the customer slot is free again (after exit anim)
	if is_inside_tree():
		await get_tree().create_timer(1.5).timeout
	if is_inside_tree():
		can_spawn = true
