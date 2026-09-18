class_name ShieldSmoke
extends CPUParticles2D


const REGEN_WARNING = 0.5
const FLICKER_STEP = 0.12
const POP_BURST_SCALE = 1.5


@export var shield: ShieldComponent


var _tween: Tween
var _burst_amount: int


@onready var _burst: CPUParticles2D = $Burst


func _ready() -> void:
	emitting = false
	_burst_amount = _burst.amount
	shield.blocked.connect(pulse)
	shield.broken.connect(pop)
	shield.shield_changed.connect(_on_shield_changed)


func disable() -> void:
	_kill_tween()
	emitting = false
	_burst.emitting = false


func fade_in() -> void:
	_kill_tween()
	emitting = true


func pulse() -> void:
	_burst.amount = _burst_amount
	_burst.restart()


func pop() -> void:
	_kill_tween()
	emitting = false
	_burst.amount = int(_burst_amount * POP_BURST_SCALE)
	_burst.restart()

	var warning_delay := shield.regen_time - REGEN_WARNING
	if shield.regen_time <= 0.0 or warning_delay <= 0.0: return
	_tween = create_tween()
	_tween.tween_interval(warning_delay)
	_tween.tween_callback(_start_regen_flicker)


func _start_regen_flicker() -> void:
	_kill_tween()
	_tween = create_tween().set_loops()
	_tween.tween_callback(set_emitting.bind(true))
	_tween.tween_interval(FLICKER_STEP)
	_tween.tween_callback(set_emitting.bind(false))
	_tween.tween_interval(FLICKER_STEP)


func _kill_tween() -> void:
	if _tween: _tween.kill()
	_tween = null


func _on_shield_changed(active: bool) -> void:
	if active: fade_in()
