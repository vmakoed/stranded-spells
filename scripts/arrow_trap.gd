class_name ArrowTrap
extends Node2D


@export var cooldown := 1.0
@export var arrow_speed := 120.0
@export var push_distance := 48.0
@export var direction := Vector2.DOWN
@export var spawn_frame := 2
@export var jam_time := 4.0
@export var arrow_scene: PackedScene = preload("res://scenes/trap_arrow.tscn")


var _active := false
var _spawned := true


@onready var _sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var _timer: Timer = %Timer
@onready var _spawn_point: Marker2D = %SpawnPoint
@onready var _jam_timer: Timer = %JamTimer
@onready var _jammed_arrow: Sprite2D = %JammedArrow


func _ready() -> void:
	_rest()
	_sprite.frame_changed.connect(_on_frame_changed)
	_sprite.animation_finished.connect(_on_animation_finished)
	_timer.timeout.connect(_on_timer_timeout)
	_jam_timer.timeout.connect(_on_jam_timer_timeout)
	%JamRing.timer = _jam_timer
	_jammed_arrow.hide()


func start() -> void:
	_active = true
	if not _is_jammed() and not _sprite.is_playing() and _timer.is_stopped(): _fire()


func stop() -> void:
	_active = false


func spawn_position() -> Vector2:
	return _spawn_point.global_position


func on_arrow_returned() -> void:
	_timer.stop()
	_jam_timer.start(jam_time)
	_jammed_arrow.show()


func _is_jammed() -> bool:
	return not _jam_timer.is_stopped()


func _fire() -> void:
	_spawned = false
	_sprite.play(&"fire")
	_sprite.set_frame_and_progress(0, 0.0)


func _rest() -> void:
	_sprite.stop()
	_sprite.animation = &"fire"
	_sprite.frame = 0


func _spawn_arrow() -> void:
	_spawned = true
	if _is_jammed(): return
	var arrow: TrapArrow = arrow_scene.instantiate()
	arrow.trap = self
	add_child(arrow)
	arrow.global_position = _spawn_point.global_position
	arrow.launch(direction, arrow_speed, push_distance)


func _on_frame_changed() -> void:
	if not _spawned and _sprite.is_playing() and _sprite.frame == spawn_frame:
		_spawn_arrow()


func _on_animation_finished() -> void:
	_rest()
	_timer.start(cooldown)


func _on_timer_timeout() -> void:
	if _active and not _is_jammed(): _fire()


func _on_jam_timer_timeout() -> void:
	_jammed_arrow.hide()
	if _active and not _sprite.is_playing() and _timer.is_stopped(): _fire()
