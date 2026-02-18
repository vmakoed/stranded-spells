class_name Door
extends StaticBody2D


enum State {CLOSED, OPEN}


const ANIMATIONS: Dictionary[State, StringName] = {
	State.CLOSED: &"closed",
	State.OPEN: &"open"
}


@export var initial_state := State.CLOSED


var state: State = State.CLOSED: set = _set_state


@onready var animated_sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = %CollisionShape2D


func _ready() -> void:
	state = initial_state


func _set_state(new_value: State) -> void:
	if state == new_value:
		return

	state = new_value
	animated_sprite.play(ANIMATIONS[state])

	match state:
		State.CLOSED: collision_shape.set_deferred("disabled", false)
		State.OPEN: collision_shape.set_deferred("disabled", true)


func open() -> void:
	state = State.OPEN


func close() -> void:
	state = State.CLOSED
