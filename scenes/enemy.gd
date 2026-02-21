class_name Enemy
extends CharacterBody2D


signal destroyed


const MAX_HEALTH = 50.0
const FREEZE_PUSH_DAMAGE = 25.0
const SHOCK_DAMAGE = 20.0
const FIRE_DAMAGE = 10.0
const PLAYER_DAMAGE_PER_HIT = 50.0

const SPEED = 20.0
const MINIMUM_DISTANCE = 10.0
const MAX_PUSH_SPEED = 25.0
const PUSH_SPEED_THRESHOLD = 1.0
const CHASE_ACCELERATION = 40.0
const CHASE_SLOWDOWN = 5.0
const FREEZE_SLOWDOWN = 50.0
const PUSH_DECAY = 10.0

const SHOCK_MODULATION_DURATION = 0.25
const PUSH_MODULATION_DURATION = 0.25
const BURN_LOOP_DURATION = 1.0
const BURNS_ASSIGNED_BY_FIRE = 3
const DAMAGE_BLINKS = 3


var health: float
var dead := false
var player: Player
var chase_velocity = Vector2.ZERO
var push_velocity = Vector2.ZERO
var frozen := false
var burns_left := 0
var initial_modulate: Color
var tween: Tween


@onready var attack_cooldown_timer: Timer = %AttackCooldownTimer
@onready var freeze_timer: Timer = %FreezeTimer
@onready var burn_timer: Timer = %BurnTimer


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
	if dead: return

	health -= damage

	if health <= 0:
		if tween: tween.stop()
		dead = true
		destroyed.emit()
		queue_free()
	else:
		if frozen: _unfreeze()


func receive_push(direction: Vector2) -> void:
	if frozen:
		take_damage(FREEZE_PUSH_DAMAGE)
		_blink_damage(SpellDefinitions.Spell.PUSH)

	push_velocity = direction * MAX_PUSH_SPEED


func receive_frost(_direction: Vector2) -> void:
	if tween: tween.stop()

	frozen = true
	modulate = SpellDefinitions.SPELL_ENEMY_COLORS[SpellDefinitions.Spell.FROST]
	freeze_timer.start()


func receive_shock(_direction: Vector2) -> void:
	take_damage(SHOCK_DAMAGE)
	_blink_damage(SpellDefinitions.Spell.SHOCK)


func receive_fire(_direction: Vector2) -> void:
	take_damage(FIRE_DAMAGE)
	burns_left = BURNS_ASSIGNED_BY_FIRE
	burn_timer.start()
	_blink_damage(SpellDefinitions.Spell.FIRE, BURNS_ASSIGNED_BY_FIRE, burn_timer.wait_time)


func _blink_damage(
	spell: SpellDefinitions.Spell, 
	damage_blinks = DAMAGE_BLINKS, 
	blink_duration = PUSH_MODULATION_DURATION
) -> void:
	if tween: tween.stop()
	modulate = SpellDefinitions.SPELL_ENEMY_COLORS[spell]
	tween = create_tween()
	tween.set_loops(damage_blinks)
	tween.tween_property(
		self,
		"modulate",
		Color(modulate - Color.BLACK),
		blink_duration
	).from(modulate)
	tween.finished.connect(func(): modulate = initial_modulate)


func _unfreeze() -> void:
	modulate = initial_modulate
	frozen = false
		

func _apply_chase_velocity(delta) -> void:
	if frozen:
		velocity = lerp(velocity, Vector2.ZERO, delta * FREEZE_SLOWDOWN)
		return

	if _is_chasing_player():
		var chase_direction := global_position.direction_to(player.global_position)
		if chase_direction.is_zero_approx(): return
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
	if frozen:
		return

	var hurtbox_owner = area.get_parent()

	if hurtbox_owner.has_method("take_damage"):
		hurtbox_owner.take_damage(PLAYER_DAMAGE_PER_HIT)


func _on_freeze_timer_timeout() -> void:
	if health <= 0.0:
		return
	_unfreeze()


func _on_burn_timer_timeout() -> void:
	burns_left -= 1

	if burns_left == 0:
		burn_timer.stop()
	else:
		take_damage(FIRE_DAMAGE)
