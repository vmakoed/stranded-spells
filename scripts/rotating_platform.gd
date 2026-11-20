class_name RotatingPlatform
extends StaticBody2D


@export var switch: Switch
@export var step_degrees := 90.0
@export var duration := 0.6
@export var save_id := ""


var _target := 0.0
var _steps := 0

@onready var _carry: Area2D = get_node_or_null("%CarryArea")


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
	var tween := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(_turn_to, rotation, deg_to_rad(_target), duration)
	tween.finished.connect(func() -> void: switch.on = false)


func _turn_to(angle: float) -> void:
	var delta := angle - rotation
	var carried := _carried_bodies()
	rotation = angle
	for body in carried:
		body.global_position = global_position + (body.global_position - global_position).rotated(delta)


func _carried_bodies() -> Array[Node2D]:
	var result: Array[Node2D] = []
	if not _carry:
		return result
	for child in _carry.get_children():
		var shape_node := child as CollisionShape2D
		if not shape_node or not shape_node.shape is RectangleShape2D:
			continue
		var half := (shape_node.shape as RectangleShape2D).size / 2.0
		for body in _carry.get_overlapping_bodies():
			var local := shape_node.to_local(body.global_position)
			if absf(local.x) <= half.x and absf(local.y) <= half.y and not result.has(body):
				result.append(body)
	return result
