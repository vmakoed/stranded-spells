class_name ShieldBubble
extends Node2D


const APPEAR_DURATION = 0.2
const HIT_KICK_DURATION = 0.3
const HIT_KICK_SCALE = 1.2
const HIT_FLASH = 0.8
const HIT_FLASH_DURATION = 0.12
const BREAK_DURATION = 0.15
const BREAK_SCALE = 1.35


@export var shield: ShieldComponent


var radius: float:
	set(value):
		radius = value
		scale = Vector2.ONE * radius / ($Sprite2D.texture.get_width() / 2.0)
var _tween: Tween


@onready var _sprite: Sprite2D = $Sprite2D
@onready var _burst: CPUParticles2D = $Burst
@onready var _material: ShaderMaterial = _sprite.material
@onready var _arrow: Sprite2D = %DirectionArrow


func _ready() -> void:
	_sprite.hide()
	shield.blocked.connect(pulse)
	shield.shield_changed.connect(_on_shield_changed)
	if shield.active: fade_in()


func _process(_delta: float) -> void:
	_arrow.visible = shield.direction != Vector2.ZERO
	if _arrow.visible: _arrow.global_rotation = shield.direction.angle()


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
	_material.set_shader_parameter(&"flash", HIT_FLASH)
	_sprite.scale = Vector2.ONE * HIT_KICK_SCALE
	_tween = create_tween().set_parallel(true)
	_tween \
		.tween_property(_material, "shader_parameter/flash", 0.0, HIT_FLASH_DURATION) \
		.set_ease(Tween.EASE_OUT)
	_tween \
		.tween_property(_sprite, "scale", Vector2.ONE, HIT_KICK_DURATION) \
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


func _kill_tween() -> void:
	if _tween: _tween.kill()
	_tween = null


func _on_shield_changed(active: bool) -> void:
	if active: fade_in()
	elif _sprite.visible: pop()
