class_name Player
extends CharacterBody2D


const SPEED = 100.0


@onready var spell_area: Area2D = %SpellArea
@onready var spell_area_sprite = %SpellAreaSprite
@onready var hurtbox_collision_shape: CollisionShape2D = %HurtBoxCollisionShape
@onready var invincibility_timer: Timer = %InvincibilityTimer


func _ready() -> void:
	SpellSystem.push_casted.connect(_on_push_casted)


func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * SPEED

	move_and_slide()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"cast_down"):
		SpellSystem.append_to_spell_sequence(&"cast_down")


func take_damage() -> void:
	print("taking damage!")
	hurtbox_collision_shape.set_deferred("disabled", true)
	invincibility_timer.start()


func _get_spell_receivers() -> Array[Node2D]:
	return spell_area.get_overlapping_bodies()


func _on_push_casted() -> void:
	var spell_area_sprite_scale = spell_area_sprite.scale
	spell_area_sprite.scale = Vector2.ZERO

	var tween = create_tween()

	tween \
		.tween_property(
			spell_area_sprite,
			"scale",
			spell_area_sprite_scale,
			0.1
		).from_current()

	tween \
		.parallel() \
		.tween_property(
			spell_area_sprite, 
			"modulate",
			Color(1, 1, 1, 0.19), 
			0.1
		).from_current()

	tween \
		.tween_property(
			spell_area_sprite, 
			"modulate",
			Color.TRANSPARENT, 
			0.25
		).from(Color(1, 1, 1, 0.19))

	for spell_receiver: Node2D in _get_spell_receivers():
		if spell_receiver.has_method(&"receive_push"):
			spell_receiver.receive_push( \
				global_position. \
				direction_to(spell_receiver.global_position). \
				normalized() \
			)


func _on_invincibility_timer_timeout() -> void:
		hurtbox_collision_shape.set_deferred("disabled", false)
