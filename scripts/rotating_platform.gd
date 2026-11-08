class_name RotatingPlatform
extends Node2D


@export var switch: Switch
@export var step_degrees := 90.0
@export var duration := 0.6


var _target := 0.0


func _ready() -> void:
	_target = rotation_degrees
	if is_instance_valid(switch):
		switch.activated.connect(_rotate)


func _rotate() -> void:
	_target += step_degrees
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "rotation", deg_to_rad(_target), duration)
	tween.finished.connect(func() -> void: switch.on = false)
