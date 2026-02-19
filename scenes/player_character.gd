class_name Player
extends CharacterBody2D


const SPEED = 100.0
const CAST_DURATION = 0.1
const CAST_FADEOUT_DURATION = 0.25


@onready var spell_area: Area2D = %SpellArea
@onready var spell_area_sprite = %SpellAreaSprite
@onready var hurtbox_collision_shape: CollisionShape2D = %HurtBoxCollisionShape
@onready var invincibility_timer: Timer = %InvincibilityTimer


func _ready() -> void:
	SpellSystem.spell_casted.connect(_on_spell_casted)


func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * SPEED

	move_and_slide()


func _input(event: InputEvent) -> void:
	for action in SpellDefinitions.SPELL_ACTIONS.values():
		if event.is_action_pressed(action):
			SpellSystem.append_to_spell_sequence(action)


func take_damage() -> void:
	print("player taking damage!")
	hurtbox_collision_shape.set_deferred("disabled", true)
	invincibility_timer.start()


func _resolve_spell_effects(spell: SpellDefinitions.Spell) -> void:
	var receiving_method := SpellDefinitions.SPELL_RECEIVING_METHODS[spell]

	for spell_receiver: Node2D in _get_spell_receivers(spell):
		if spell_receiver.has_method(receiving_method):
			spell_receiver.call( 
				receiving_method, \
				global_position. \
				direction_to(spell_receiver.global_position). \
				normalized() \
			)


func _get_spell_receivers(spell: SpellDefinitions.Spell) -> Array:
	var bodies_in_spell_area := spell_area.get_overlapping_bodies()

	if bodies_in_spell_area.is_empty():
		return []

	if spell in SpellDefinitions.ROOM_WIDE_SPELLS:
		return get_tree().get_nodes_in_group("enemies")
	else:
		return bodies_in_spell_area


func _reveal_spell_area(tween: Tween, spell: SpellDefinitions.Spell) -> void:
	var spell_area_sprite_scale = spell_area_sprite.scale
	spell_area_sprite.scale = Vector2.ZERO
	tween \
		.tween_property(
			spell_area_sprite,
			"scale",
			spell_area_sprite_scale,
			CAST_DURATION
		).from_current()

	tween \
		.parallel() \
		.tween_property(
			spell_area_sprite, 
			"modulate",
			SpellDefinitions.SPELL_AREA_COLORS[spell], 
			CAST_DURATION
		).from_current()


func _hide_spell_area(tween: Tween, spell: SpellDefinitions.Spell) -> void:
	var transparency_difference: Color = Color(0, 0, 0, SpellDefinitions.SPELL_COLOR_TRANSPARENCY)
	
	tween \
		.tween_property(
			spell_area_sprite, 
			"modulate",
			SpellDefinitions.SPELL_AREA_COLORS[spell] - transparency_difference, 
			CAST_FADEOUT_DURATION
		).from(SpellDefinitions.SPELL_AREA_COLORS[spell])


func _on_spell_casted(spell: SpellDefinitions.Spell) -> void:
	var tween = create_tween()
	_reveal_spell_area(tween, spell)
	tween.tween_callback(_resolve_spell_effects.bind(spell))
	_hide_spell_area(tween, spell)


func _on_invincibility_timer_timeout() -> void:
		hurtbox_collision_shape.set_deferred("disabled", false)
