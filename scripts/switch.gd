@tool
class_name Switch
extends StaticBody2D


signal activated


const OFF_TEXTURE := preload("res://assets/textures/switch_red.png")
const ON_TEXTURE := preload("res://assets/textures/switch_green.png")


@export var on := false:
	set(value):
		on = value
		_apply()

@export var doors: Array[ChallengeDoor] = []
@export var wire: TileMapLayer
@export var save_id := ""


@onready var sprite: Sprite2D = %Sprite2D


func _ready() -> void:
	_apply()
	if Engine.is_editor_hint(): return
	if GameState.get_flag(self, false):
		on = true
		for door in doors:
			if is_instance_valid(door): door.closed = false


func activate() -> void:
	if on: return
	on = true
	if Engine.is_editor_hint(): return
	GameState.set_flag(self, true)
	for door in doors:
		if is_instance_valid(door): door.open()
	activated.emit()


func _apply() -> void:
	if not is_node_ready(): return
	sprite.texture = ON_TEXTURE if on else OFF_TEXTURE
	if not Engine.is_editor_hint() and is_instance_valid(wire):
		wire.modulate = ProgressRing.FILL_COLOR if on else Color.WHITE
