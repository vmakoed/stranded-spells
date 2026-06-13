class_name Door
extends StaticBody2D


enum State {CLOSED, OPEN}


const ANIMATIONS: Dictionary[State, StringName] = {
	State.CLOSED: &"closed",
	State.OPEN: &"open"
}


@export var initial_state := State.CLOSED
@export var open_sound: AudioStream
@export var close_sound: AudioStream


var state: State = State.CLOSED: set = _set_state


@onready var animated_sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = %CollisionShape2D
@onready var audio_stream_player: AudioStreamPlayer2D = %AudioStreamPlayer2D


func _ready() -> void:
	state = initial_state


func _set_state(new_value: State) -> void:
	animated_sprite.play(ANIMATIONS[new_value])

	if state == new_value:
		return

	state = new_value

	match state:
		State.CLOSED: collision_shape.set_deferred("disabled", false)
		State.OPEN: collision_shape.set_deferred("disabled", true)


func open(with_sound = false) -> void:
	if with_sound: play_sound(open_sound)
	state = State.OPEN


func close(with_sound = false) -> void:
	if with_sound: play_sound(close_sound)
	state = State.CLOSED


func play_sound(sound: AudioStream) -> void:
	if not sound: return
	audio_stream_player.stream = sound
	audio_stream_player.play()
