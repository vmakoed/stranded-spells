class_name LockedDoor
extends StaticBody2D


const OPEN_FADE_DURATION = 0.3


@export var key: Player.Item
@export var key_icon: Texture2D
@export var tint := Color.WHITE
@export var open_sound: AudioStream


var _opening := false


@onready var sprite: Sprite2D = %Sprite2D
@onready var collision_shape: CollisionShape2D = %CollisionShape2D
@onready var sense_area: Area2D = %SenseArea
@onready var audio_stream_player: AudioStreamPlayer2D = %AudioStreamPlayer2D


func _ready() -> void:
	sprite.modulate = tint


func _on_sense_area_body_entered(body: Node2D) -> void:
	if _opening: return
	if body is not Player: return
	if body.has_item(key):
		_open()
	else:
		body.show_hint(key_icon)


func _open() -> void:
	_opening = true
	collision_shape.set_deferred("disabled", true)
	sense_area.set_deferred("monitoring", false)

	if open_sound:
		audio_stream_player.stream = open_sound
		audio_stream_player.play()

	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, OPEN_FADE_DURATION)
	await tween.finished
	if audio_stream_player.playing: await audio_stream_player.finished
	queue_free()
