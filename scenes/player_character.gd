class_name Player
extends CharacterBody2D


signal destroyed


const MAX_HEALTH = 300.0
const SPEED = 100.0
const CAST_FADEOUT_DURATION = 0.25
const INVINCIBILITY_BLINK_FREQUENCY = 0.1
const CAST_FRAME_FREEZE_TIME_SCALE = 0.01
const CAST_FRAME_FREEZE_DURATION = 0.15


@export var push_sound: AudioStream
@export var frost_sound: AudioStream
@export var shock_sound: AudioStream
@export var fire_sound: AudioStream
@export var hit_sound: AudioStream
@export var pickup_sound: AudioStream


var health: float: set = _set_health
var invincible := false
var dead := false
var invincibility_tween: Tween 
var initial_sprite_modulate: Color


@onready var spell_area: Area2D = %SpellArea
@onready var hurtbox_collision_shape: CollisionShape2D = %HurtBoxCollisionShape
@onready var invincibility_timer: Timer = %InvincibilityTimer
@onready var character_sprite: Sprite2D = %CharacterSprite
@onready var audio_stream_player: AudioStreamPlayer2D = %AudioStreamPlayer2D


func _ready() -> void:
	health = GameState.get_player_character_health()
	# SpellSystem.spell_casted.connect(_on_spell_casted)
	initial_sprite_modulate = character_sprite.modulate


func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * SPEED

	move_and_slide()


func _input(event: InputEvent) -> void:
	for action in SpellDefinitions.SPELL_ACTIONS.values():
		if event.is_action_pressed(action):
			return SpellSystem.append_to_spell_sequence(action)


func take_damage(damage: float) -> void:
	if dead: return

	if not invincible:
		health -= damage
		_play_hit_sound()
		_blink_sprite()
		
	if health <= 0:
		dead = true
		destroyed.emit()
		queue_free()
	else:
		invincible = true
		hurtbox_collision_shape.set_deferred("disabled", true)
		invincibility_timer.start()


func save_health() -> void:
	GameState.set_player_character_health(health)


func play_pickup_sound() -> void:
	if not pickup_sound: return
	audio_stream_player.stream = pickup_sound
	audio_stream_player.play()


func receive_push(_vector: Vector2) -> void:
	print("player received push")


func focus() -> void:
	$FocusSprite.show()


func unfocus() -> void:
	$FocusSprite.hide()


func show_spell_area() -> void:
	spell_area.show()


func hide_spell_area() -> void:
	spell_area.hide()


func get_spell_area_bodies() -> Array[Node2D]:
	return spell_area.get_overlapping_bodies()


func _set_health(new_value: float) -> void:
	health = new_value
	GameUIBridge.health_changed.emit(health, MAX_HEALTH)


func _blink_sprite() -> void:
	invincibility_tween = create_tween()
	invincibility_tween.set_loops()
	invincibility_tween.tween_property(
		character_sprite,
		"modulate",
		Color(initial_sprite_modulate - Color.BLACK),
		INVINCIBILITY_BLINK_FREQUENCY
	).from(initial_sprite_modulate)


func _resolve_spell_effects(spell: SpellDefinitions.Spell) -> void:
	var receiving_method := SpellDefinitions.SPELL_RECEIVING_METHODS[spell]
	# var spell_receivers := _get_spell_receivers(spell)
	var spell_receivers := get_spell_receivers_ordered_by_distance()
	_play_spell_sound(spell)
	if spell_receivers.is_empty(): return

	spell_receivers.resize(1)

	Engine.time_scale = CAST_FRAME_FREEZE_TIME_SCALE
	get_tree() \
		.create_timer(
			CAST_FRAME_FREEZE_DURATION, true, false, true
		).timeout \
		.connect(
			func(): Engine.time_scale = 1.0
		)

	for spell_receiver: Node2D in spell_receivers:
		print(spell_receiver)
		if spell_receiver.has_method(receiving_method):
			spell_receiver.call(
				receiving_method, \
				global_position.\
				direction_to(spell_receiver.global_position).\
				normalized() \
			)


func _get_spell_receivers(spell: SpellDefinitions.Spell) -> Array:
	var targets := spell_area.get_overlapping_bodies()

	if targets.is_empty():
		return []

	if spell in SpellDefinitions.ROOM_WIDE_SPELLS:
		targets.append_array(
			get_tree() \
				.get_nodes_in_group("enemies") \
				.filter(
					func(enemy): return not (enemy in targets)
				)
		)
		return targets
	else:
		return targets


func get_spell_receivers_ordered_by_distance() -> Array[Node]:
	var spell_receivers = get_tree().get_nodes_in_group("enemies")

	for receiver in spell_receivers:
		print(global_position.distance_to(receiver.global_position))

	spell_receivers \
		.sort_custom(
			func(node_1, node_2): return \
				global_position \
					.distance_to(node_1.global_position) < \
					global_position \
						.distance_to(node_2.global_position)
		)
	return spell_receivers


func _play_spell_sound(spell: SpellDefinitions.Spell) -> void:
	var sound = _get_spell_stream(spell)
	if not sound: return
	audio_stream_player.stream = sound

	match spell:
		SpellDefinitions.Spell.SHOCK:
			audio_stream_player.play(0.5)
		_:
			audio_stream_player.play()


func _play_hit_sound() -> void:
	var sound = hit_sound
	if not sound: return
	audio_stream_player.stream = sound
	audio_stream_player.play()


func _get_spell_stream(spell: SpellDefinitions.Spell) -> AudioStream:
	match spell:
		SpellDefinitions.Spell.PUSH: return push_sound
		SpellDefinitions.Spell.FROST: return frost_sound
		SpellDefinitions.Spell.SHOCK: return shock_sound
		SpellDefinitions.Spell.FIRE: return fire_sound
		_: return push_sound


func _on_spell_casted(spell: SpellDefinitions.Spell) -> void:
	spell_area.animate(spell, _resolve_spell_effects.bind(spell))


func _on_invincibility_timer_timeout() -> void:
	if invincibility_tween: invincibility_tween.stop()
	character_sprite.modulate = initial_sprite_modulate
	hurtbox_collision_shape.set_deferred("disabled", false)
	invincible = false
