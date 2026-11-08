class_name RotatingPlatform
extends Node2D


@export var switch: Switch
@export var step_degrees := 90.0
@export var duration := 0.6
@export var save_id := ""


var _target := 0.0
var _steps := 0


func _ready() -> void:
	_steps = GameState.get_flag(self, 0)
	_target = rotation_degrees + _steps * step_degrees
	rotation_degrees = _target
	if is_instance_valid(switch):
		switch.activated.connect(_rotate)


func _rotate() -> void:
	_steps += 1
	if is_zero_approx(fmod(360.0, step_degrees)):
		_steps %= roundi(360.0 / step_degrees)
	_target += step_degrees
	GameState.set_flag(self, _steps)
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "rotation", deg_to_rad(_target), duration)
	tween.finished.connect(func() -> void: switch.on = false)
