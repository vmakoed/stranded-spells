@tool
class_name PressurePlate
extends Area2D


signal pressed
signal released


const LINK_COLOR := Color(1, 0.4, 0.3, 0.6)


@export var spikes: Array[Spikes] = []
@export_flags_2d_physics var triggered_by := 1 | 8


var _count := 0


func _ready() -> void:
	if Engine.is_editor_hint(): return
	set_process(false)
	collision_layer = 0
	collision_mask = triggered_by
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	if Engine.is_editor_hint(): queue_redraw()


func _draw() -> void:
	if not Engine.is_editor_hint(): return
	for s in spikes:
		if is_instance_valid(s): draw_line(Vector2.ZERO, to_local(s.global_position), LINK_COLOR)


func _on_body_entered(_body: Node2D) -> void:
	_count += 1
	if _count != 1: return
	for s in spikes:
		if is_instance_valid(s): s.raise()
	pressed.emit()


func _on_body_exited(_body: Node2D) -> void:
	_count = maxi(_count - 1, 0)
	if _count != 0: return
	for s in spikes:
		if is_instance_valid(s): s.lower()
	released.emit()
