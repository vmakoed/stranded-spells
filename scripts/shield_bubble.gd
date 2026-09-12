class_name ShieldBubble
extends Sprite2D


const PULSE_SCALE = 1.3
const PULSE_DURATION = 0.08
const POP_SCALE = 1.6
const POP_DURATION = 0.15
const FADE_IN_DURATION = 0.25
const REGEN_WARNING = 0.5
const FLICKER_STEP = 0.08


@export var shield: ShieldComponent


var _tween: Tween
var _base_scale: Vector2
var _base_alpha: float


func _ready() -> void:
	_base_scale = scale
	_base_alpha = modulate.a
	shield.blocked.connect(pulse)
	shield.broken.connect(pop)
	shield.shield_changed.connect(_on_shield_changed)


func disable() -> void:
	_kill_tween()
	hide()


func fade_in() -> void:
	_kill_tween()
	scale = _base_scale
	modulate.a = 0.0
	show()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", _base_alpha, FADE_IN_DURATION)


func pulse() -> void:
	_kill_tween()
	modulate.a = _base_alpha
	scale = _base_scale
	_tween = create_tween()
	_tween \
		.tween_property(self, "scale", _base_scale * PULSE_SCALE, PULSE_DURATION) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_OUT)
	_tween \
		.tween_property(self, "scale", _base_scale, PULSE_DURATION) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_IN)


func pop() -> void:
	_kill_tween()
	_tween = create_tween().set_parallel(true)
	_tween \
		.tween_property(self, "scale", _base_scale * POP_SCALE, POP_DURATION) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "modulate:a", 0.0, POP_DURATION)
	_tween.set_parallel(false)
	_tween.tween_callback(hide)

	var warning_delay := shield.regen_time - POP_DURATION - REGEN_WARNING
	if shield.regen_time <= 0.0 or warning_delay <= 0.0: return
	_tween.tween_interval(warning_delay)
	_tween.tween_callback(_start_regen_flicker)


func _start_regen_flicker() -> void:
	_kill_tween()
	scale = _base_scale
	modulate.a = 0.0
	show()
	_tween = create_tween().set_loops()
	_tween.tween_property(self, "modulate:a", _base_alpha * 0.5, FLICKER_STEP)
	_tween.tween_property(self, "modulate:a", 0.0, FLICKER_STEP)


func _kill_tween() -> void:
	if _tween: _tween.kill()
	_tween = null


func _on_shield_changed(active: bool) -> void:
	if active: fade_in()
