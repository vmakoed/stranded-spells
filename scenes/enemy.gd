class_name Enemy
extends CharacterBody2D


signal destroyed


const MAX_HEALTH = 100.0
const FREEZE_PUSH_DAMAGE = 50.0
const SHOCK_DAMAGE = 25.0
const FIRE_DAMAGE = 30.0
const PLAYER_DAMAGE_PER_HIT = 50.0

const SPEED = 50.0
const MINIMUM_DISTANCE = 10.0
const MAX_PUSH_SPEED = 50.0
const PUSH_SPEED_THRESHOLD = 1.0
const CHASE_ACCELERATION = 40.0
const CHASE_SLOWDOWN = 5.0
const FREEZE_SLOWDOWN = 50.0
const PUSH_DECAY = 10.0

const SHOCK_MODULATION_DURATION = 0.75
const BURN_MODULATION_DURATION = 1.0
const BURN_LOOPS = 3


var health: float
var player: Player
var chase_velocity = Vector2.ZERO
var push_velocity = Vector2.ZERO
var frozen := false
var initial_modulate: Color
var tween: Tween


@onready var attack_cooldown_timer: Timer = %AttackCooldownTimer
@onready var freeze_timer: Timer = %FreezeTimer


func _ready() -> void:
	initial_modulate = modulate
	health = MAX_HEALTH


func _physics_process(delta: float) -> void:
	_apply_push_velocity()
	_decay_push_velocity(delta)
	
	if player: 
		_apply_chase_velocity(delta)
	
	move_and_slide()


func take_damage(damage: float) -> void:
	print("enemy taking ", damage, " damage!")
	health -= damage

	if health <= 0:
		if tween: tween.stop()
		destroyed.emit()
		queue_free()
	else:
		if frozen: _unfreeze()


func receive_push(direction: Vector2) -> void:
	if frozen:
		take_damage(FREEZE_PUSH_DAMAGE)

	push_velocity = direction * MAX_PUSH_SPEED


func receive_frost(_direction: Vector2) -> void:
	if tween: tween.stop()

	frozen = true
	modulate = SpellDefinitions.SPELL_ENEMY_COLORS[SpellDefinitions.Spell.FROST]
	freeze_timer.start()


func receive_shock(_direction: Vector2) -> void:
	if tween: tween.stop()

	tween = create_tween()
	tween \
		.tween_property(
			self, 
			"modulate",
			SpellDefinitions.SPELL_ENEMY_COLORS[SpellDefinitions.Spell.SHOCK], 
			0.05
		).from_current()
	tween.tween_callback(take_damage.bind(SHOCK_DAMAGE))
	tween.tween_interval(SHOCK_MODULATION_DURATION)
	tween \
		.tween_property(
			self, 
			"modulate",
			initial_modulate, 
			0.05
		).from(SpellDefinitions.SPELL_ENEMY_COLORS[SpellDefinitions.Spell.SHOCK])

func receive_fire(_direction: Vector2) -> void:
	if tween: tween.stop()

	modulate = SpellDefinitions.SPELL_ENEMY_COLORS[SpellDefinitions.Spell.FIRE]
	tween = create_tween()
	tween.set_loops(BURN_LOOPS)
	tween.tween_callback(take_damage.bind(FIRE_DAMAGE))
	tween \
		.tween_property(
			self, 
			"modulate",
			initial_modulate, 
			BURN_MODULATION_DURATION
		).from(SpellDefinitions.SPELL_ENEMY_COLORS[SpellDefinitions.Spell.FIRE])


func _unfreeze() -> void:
	modulate = initial_modulate
	frozen = false
		

func _apply_chase_velocity(delta) -> void:
	if frozen:
		velocity = lerp(velocity, Vector2.ZERO, delta * FREEZE_SLOWDOWN)
		return

	if _is_chasing_player():
		chase_velocity = global_position.direction_to(player.global_position) * SPEED
		velocity = lerp(velocity, chase_velocity, delta * CHASE_ACCELERATION)
	else:
		velocity = lerp(velocity, Vector2.ZERO, delta * CHASE_SLOWDOWN)


func _is_chasing_player() -> bool:
	return (push_velocity.length() < PUSH_SPEED_THRESHOLD) \
		and (global_position.distance_to(player.global_position) > MINIMUM_DISTANCE)


func _apply_push_velocity() -> void:
	velocity += push_velocity


func _decay_push_velocity(delta) -> void:
	push_velocity = lerp(push_velocity, Vector2.ZERO, PUSH_DECAY * delta)


func _on_attack_area_area_entered(area: Area2D) -> void:
	var hurtbox_owner = area.get_parent()

	if hurtbox_owner.has_method("take_damage"):
		hurtbox_owner.take_damage(PLAYER_DAMAGE_PER_HIT)


func _on_freeze_timer_timeout() -> void:
	if health <= 0.0:
		return
	_unfreeze()
