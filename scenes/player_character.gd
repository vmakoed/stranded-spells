extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0


@onready var spell_area: Area2D = %SpellArea


func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * SPEED

	move_and_slide()


func get_spell_receivers() -> Array[Node2D]:
	return spell_area.get_overlapping_bodies()
