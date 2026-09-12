class_name ShieldComponent
extends Node


signal shield_changed(active: bool)
signal blocked
signal broken


enum Mode { WARD, BARRIER }


@export var mode := Mode.BARRIER
@export var regen_time := 0.0


var active := false: set = _set_active


@onready var _regen_timer: Timer = $RegenTimer


func activate() -> void:
	_regen_timer.stop()
	active = true


func disable() -> void:
	_regen_timer.stop()
	active = false


func try_absorb(_value: float, breaks_shield: bool) -> bool:
	if not active: return false

	if breaks_shield or mode == Mode.WARD:
		active = false
		broken.emit()
		if regen_time > 0.0:
			_regen_timer.start(regen_time)
		return mode == Mode.WARD

	blocked.emit()
	return true


func _set_active(new_value: bool) -> void:
	if new_value == active: return
	active = new_value
	shield_changed.emit(active)


func _on_regen_timer_timeout() -> void:
	activate()
