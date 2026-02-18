class_name Player
extends CharacterBody2D


const SPEED = 100.0


@onready var spell_area: Area2D = %SpellArea


func _ready() -> void:
	SpellSystem.push_casted.connect(_on_push_casted)


func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * SPEED

	move_and_slide()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"cast_down"):
		SpellSystem.append_to_spell_sequence(&"cast_down")


func get_spell_receivers() -> Array[Node2D]:
	return spell_area.get_overlapping_bodies()


func _on_push_casted() -> void:
	for spell_receiver: Node2D in get_spell_receivers():
		if spell_receiver.has_method(&"receive_push"):
			spell_receiver.receive_push( \
				global_position. \
				direction_to(spell_receiver.global_position). \
				normalized() \
			)
