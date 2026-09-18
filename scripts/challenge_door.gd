@tool
class_name ChallengeDoor
extends StaticBody2D


enum Facing { TOP, SIDE }


const OPEN_FADE_DURATION := 0.3
const EDITOR_OPEN_ALPHA := 0.5
const TOP_TEXTURE := preload("res://resources/door_top.tres")
const SIDE_TEXTURE := preload("res://resources/door_side.tres")
const TOP_SHAPE := preload("res://resources/door_top_shape.tres")
const SIDE_SHAPE := preload("res://resources/door_side_shape.tres")
const TOP_SHAPE_OFFSET := Vector2(0, 2)
const SIDE_SHAPE_OFFSET := Vector2.ZERO


@export var facing: Facing = Facing.TOP:
	set(value):
		facing = value
		_apply()

@export var closed := false:
	set(value):
		closed = value
		_apply()

@export var open_sound: AudioStream
@export var close_sound: AudioStream


@onready var sprite: Sprite2D = %Sprite2D
@onready var collision_shape: CollisionShape2D = %CollisionShape2D
@onready var audio_stream_player: AudioStreamPlayer2D = %AudioStreamPlayer2D


var _tween: Tween


func _ready() -> void:
	_apply()


func open() -> void:
	if not closed: return
	closed = false
	if Engine.is_editor_hint(): return
	_play(open_sound)
	sprite.visible = true
	_tween = create_tween()
	_tween.tween_property(sprite, "modulate:a", 0.0, OPEN_FADE_DURATION)
	_tween.tween_callback(sprite.hide)


func close() -> void:
	if closed: return
	closed = true
	if Engine.is_editor_hint(): return
	_play(close_sound)


func _apply() -> void:
	if not is_node_ready(): return
	if _tween: _tween.kill()
	sprite.texture = _texture()
	collision_shape.shape = _shape()
	collision_shape.position = _shape_offset()
	if Engine.is_editor_hint():
		sprite.visible = true
		sprite.modulate.a = 1.0 if closed else EDITOR_OPEN_ALPHA
		collision_shape.disabled = not closed
		return
	sprite.modulate.a = 1.0
	sprite.visible = closed
	collision_shape.set_deferred("disabled", not closed)


func _play(stream: AudioStream) -> void:
	if stream == null: return
	audio_stream_player.stream = stream
	audio_stream_player.play()


func _texture() -> Texture2D:
	return SIDE_TEXTURE if facing == Facing.SIDE else TOP_TEXTURE


func _shape() -> Shape2D:
	return SIDE_SHAPE if facing == Facing.SIDE else TOP_SHAPE


func _shape_offset() -> Vector2:
	return SIDE_SHAPE_OFFSET if facing == Facing.SIDE else TOP_SHAPE_OFFSET
