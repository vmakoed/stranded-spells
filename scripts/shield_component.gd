class_name ShieldComponent
extends Node


signal shield_changed(active: bool)
signal blocked


var active := false: set = _set_active


static func deflect_direction(hit: Vector2, center: Vector2) -> Vector2:
	var offset := hit - center
	if absf(offset.x) > absf(offset.y): return Vector2(signf(offset.x), 0.0)
	return Vector2(0.0, signf(offset.y) if offset.y != 0.0 else -1.0)


func activate() -> void:
	active = true


func disable() -> void:
	active = false


func try_absorb(_value: float) -> bool:
	if not active: return false
	blocked.emit()
	return true


func _set_active(new_value: bool) -> void:
	if new_value == active: return
	active = new_value
	shield_changed.emit(active)
