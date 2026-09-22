class_name ShieldBubble
extends Node2D


const APPEAR_DURATION = 0.2
const HIT_WOBBLE_DURATION = 0.45
const HIT_WOBBLE_AMOUNT = 0.14
const HIT_KICK_SCALE = 1.08
const BREAK_DURATION = 0.15
const BREAK_SCALE = 1.35
const REGEN_WARNING = 1.2
const WARNING_BLINKS = 3
const WARNING_STEP = 0.4
const WARNING_ALPHA = 0.4
const WARNING_HOLD = 0.12


@export var shield: ShieldComponent


var _tween: Tween
var _rest_wobble: float


@onready var _sprite: Sprite2D = $Sprite2D
@onready var _burst: CPUParticles2D = $Burst
@onready var _material: ShaderMaterial = _sprite.material


func _ready() -> void:
	_sprite.hide()
	_rest_wobble = _material.get_shader_parameter(&"wobble")
	shield.blocked.connect(pulse)
	shield.broken.connect(pop)
	shield.shield_changed.connect(_on_shield_changed)
	if shield.active: fade_in()


func disable() -> void:
	_kill_tween()
	_sprite.hide()
	_burst.emitting = false


func fade_in() -> void:
	_kill_tween()
	_material.set_shader_parameter(&"flash", 0.0)
	_sprite.modulate.a = 1.0
	_sprite.scale = Vector2.ZERO
	_sprite.show()
	_tween = create_tween()
	_tween \
		.tween_property(_sprite, "scale", Vector2.ONE, APPEAR_DURATION) \
		.set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)


func pulse() -> void:
	_kill_tween()
	_material.set_shader_parameter(&"wobble", HIT_WOBBLE_AMOUNT)
	_sprite.scale = Vector2.ONE * HIT_KICK_SCALE
	_tween = create_tween().set_parallel(true)
	_tween \
		.tween_property(_material, "shader_parameter/wobble", _rest_wobble, HIT_WOBBLE_DURATION) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_OUT)
	_tween \
		.tween_property(_sprite, "scale", Vector2.ONE, HIT_WOBBLE_DURATION) \
		.set_trans(Tween.TRANS_ELASTIC) \
		.set_ease(Tween.EASE_OUT)


func pop() -> void:
	_burst.restart()

	_kill_tween()
	_material.set_shader_parameter(&"flash", 1.0)
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(_sprite, "scale", Vector2.ONE * BREAK_SCALE, BREAK_DURATION)
	_tween.tween_property(_sprite, "modulate:a", 0.0, BREAK_DURATION)
	_tween.set_parallel(false).tween_callback(_sprite.hide)

	var warning_delay := shield.regen_time - REGEN_WARNING
	if shield.regen_time <= 0.0 or warning_delay <= 0.0: return
	_tween.tween_interval(warning_delay)
	for i in WARNING_BLINKS:
		_tween.tween_callback(_warning_blink)
		_tween.tween_interval(WARNING_STEP)


func _warning_blink() -> void:
	_material.set_shader_parameter(&"flash", 0.0)
	_sprite.scale = Vector2.ONE
	_sprite.modulate.a = WARNING_ALPHA
	_sprite.show()
	var blink := create_tween()
	blink.tween_interval(WARNING_HOLD)
	blink.tween_callback(_sprite.hide)


func _kill_tween() -> void:
	if _tween: _tween.kill()
	_tween = null


func _on_shield_changed(active: bool) -> void:
	if active: fade_in()
