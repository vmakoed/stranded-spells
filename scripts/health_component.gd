class_name HealthComponent
extends Node


signal damaged(value: float)
signal health_below_minimum
signal health_changed(new_value: float)	# add old_value


const MIN_HEALTH = 0.0


@export var max_health: float: set = _set_max_health
@export var health_bar: ProgressBar: set = _set_health_bar


var health: float: set = _set_health


func _ready() -> void:
	reset()


func reset() -> void:
	health = max_health


func damage(value: float) -> void:
	if not is_alive(): return
	damaged.emit(value)
	health -= value


func heal(value: float) -> void:
	health += value


func is_alive() -> bool:
	return health > MIN_HEALTH


func _set_max_health(value: float) -> void:
	if value == max_health: return
	max_health = value
	if health_bar: health_bar.max_value = max_health


func _set_health(value: float) -> void:
	if value == health: return
	health = clamp(value, MIN_HEALTH, max_health)
	if health_bar: health_bar.value = health
	health_changed.emit(health)
	if not is_alive(): health_below_minimum.emit()


func _set_health_bar(value: ProgressBar) -> void:
	if value == health_bar: return
	health_bar = value
	health_bar.max_value = max_health
	health_bar.value = health
