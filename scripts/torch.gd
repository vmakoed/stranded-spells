@tool
class_name Torch
extends Area2D

signal ignited

enum Facing { TOP, DOWN, LEFT, RIGHT, FLOOR }

const LIT_TOP_TEXTURE := preload("res://assets/textures/torch_1.png")
const LIT_SIDE_TEXTURE := preload("res://assets/textures/side_torch_1.png")
const LIT_FLOOR_TEXTURE := preload("res://assets/textures/candlestick_1_3.png")
const UNLIT_TOP_TEXTURE := preload("res://assets/textures/torch_unlit_top_v2.png")
const UNLIT_SIDE_TEXTURE := preload("res://assets/textures/torch_unlit_side_v2.png")
const UNLIT_FLOOR_TEXTURE := preload("res://assets/textures/candlestick_1_3_unlit.png")
const LIGHT_ENERGY := 1.2
const IGNITE_DURATION := 0.3

@export var facing: Facing = Facing.TOP:
	set(value):
		facing = value
		_apply()

@export var lit := true:
	set(value):
		lit = value
		_apply()

@onready var sprite: Sprite2D = %Sprite2D
@onready var light: PointLight2D = %PointLight2D

var _tween: Tween


func _ready() -> void:
	_apply()


func ignite() -> void:
	if lit: return
	lit = true
	if Engine.is_editor_hint(): return

	light.energy = 0.0
	if _tween: _tween.kill()
	_tween = create_tween()
	_tween.tween_property(light, "energy", LIGHT_ENERGY, IGNITE_DURATION)
	ignited.emit()


func _apply() -> void:
	if not is_node_ready():
		return
	sprite.visible = facing != Facing.DOWN
	sprite.flip_h = facing == Facing.RIGHT
	sprite.texture = _texture()
	light.enabled = lit
	light.energy = LIGHT_ENERGY


func _texture() -> Texture2D:
	match facing:
		Facing.FLOOR:
			return LIT_FLOOR_TEXTURE if lit else UNLIT_FLOOR_TEXTURE
		Facing.LEFT, Facing.RIGHT:
			return LIT_SIDE_TEXTURE if lit else UNLIT_SIDE_TEXTURE
		_:
			return LIT_TOP_TEXTURE if lit else UNLIT_TOP_TEXTURE
