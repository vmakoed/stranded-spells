class_name ShieldComponent
extends Node


signal shield_changed(active: bool)
signal blocked


var active := false: set = _set_active
var direction := Vector2.ZERO


func activate() -> void:
	active = true


func disable() -> void:
	active = false


func try_absorb(_value: float) -> bool:
	if not active: return false
	blocked.emit()
	return true


func deflect(velocity: Vector2) -> Vector2:
	if direction == Vector2.ZERO: return -velocity
	return direction.normalized() * velocity.length()


func _set_active(new_value: bool) -> void:
	if new_value == active: return
	active = new_value
	shield_changed.emit(active)
