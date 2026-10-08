class_name SpikesTrap
extends Node2D


@onready var _plate: Area2D = $PressurePlate
@onready var _spikes: Area2D = $Spikes
@onready var _sprite: AnimatedSprite2D = $Spikes/AnimatedSprite2D

var _count := 0


func _ready() -> void:
	_plate.collision_layer = 0
	_plate.collision_mask = 1 | 8
	_plate.body_entered.connect(_on_body_entered)
	_plate.body_exited.connect(_on_body_exited)
	_spikes.collision_layer = 0
	_spikes.collision_mask = 0
	_spikes.monitoring = false
	_sprite.animation = &"turn_off"
	_sprite.frame = _sprite.sprite_frames.get_frame_count(&"turn_off") - 1


func _on_body_entered(_body: Node2D) -> void:
	_count += 1
	if _count == 1:
		_sprite.play(&"turn_on")


func _on_body_exited(_body: Node2D) -> void:
	_count = maxi(_count - 1, 0)
	if _count == 0:
		_sprite.play(&"turn_off")
