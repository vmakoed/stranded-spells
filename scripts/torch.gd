@tool
extends Node2D

enum Facing { TOP, DOWN, LEFT, RIGHT }

const REGION_TOP := Rect2(0, 144, 16, 16)
const REGION_SIDE := Rect2(16, 144, 16, 16)

@export var facing: Facing = Facing.TOP:
	set(value):
		facing = value
		_apply()

@onready var sprite: Sprite2D = %Sprite2D


func _ready() -> void:
	_apply()


func _apply() -> void:
	if not is_node_ready():
		return
	sprite.visible = facing != Facing.DOWN
	sprite.flip_h = facing == Facing.RIGHT
	sprite.region_rect = REGION_TOP if facing == Facing.TOP else REGION_SIDE
