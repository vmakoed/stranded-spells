class_name StunComponent
extends Node


signal stunned
signal recovered


@export var max_poise := 100.0
@export var stun_duration := 3.0
@export var regen_delay := 2.0
@export var regen_rate := 5.0
@export var warning_time := 1.2


var poise: float
var _regen_wait := 0.0
var _stun_left := 0.0


func _ready() -> void:
	poise = max_poise


func stun_damage(value: float) -> void:
	if value <= 0.0 or is_stunned() or not is_physics_processing():
		return
	poise = maxf(poise - value, 0.0)
	_regen_wait = regen_delay
	print("[stun] %s poise %d/%d" % [owner.name, poise, max_poise])
	if poise <= 0.0:
		_stun_left = stun_duration
		print("[stun] %s STUNNED for %.1fs" % [owner.name, stun_duration])
		stunned.emit()


func is_stunned() -> bool:
	return _stun_left > 0.0


func stun_remaining() -> float:
	return _stun_left


func stop() -> void:
	_stun_left = 0.0
	set_physics_process(false)


func _physics_process(delta: float) -> void:
	if is_stunned():
		_stun_left -= delta
		if _stun_left <= 0.0:
			_stun_left = 0.0
			poise = max_poise
			print("[stun] %s recovered, poise reset" % owner.name)
			recovered.emit()
		return
	if poise >= max_poise:
		return
	if _regen_wait > 0.0:
		_regen_wait -= delta
		return
	poise = minf(poise + regen_rate * delta, max_poise)
	if poise >= max_poise:
		print("[stun] %s poise regenerated" % owner.name)
