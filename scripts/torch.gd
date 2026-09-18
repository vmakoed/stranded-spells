@tool
class_name Torch
extends Area2D

signal ignited

enum Facing { TOP, DOWN, LEFT, RIGHT }

const LIT_TEXTURE := preload("res://assets/textures/Dungeon_Tileset.png")
const UNLIT_TOP_TEXTURE := preload("res://assets/textures/torch_unlit_top_v2.png")
const UNLIT_SIDE_TEXTURE := preload("res://assets/textures/torch_unlit_side_v2.png")
const REGION_TOP := Rect2(0, 144, 16, 16)
const REGION_SIDE := Rect2(16, 144, 16, 16)
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
	var top := facing == Facing.TOP
	sprite.visible = facing != Facing.DOWN
	sprite.flip_h = facing == Facing.RIGHT
	sprite.region_enabled = lit
	if lit:
		sprite.texture = LIT_TEXTURE
		sprite.region_rect = REGION_TOP if top else REGION_SIDE
	else:
		sprite.texture = UNLIT_TOP_TEXTURE if top else UNLIT_SIDE_TEXTURE
	light.enabled = lit
	light.energy = LIGHT_ENERGY
