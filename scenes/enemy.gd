class_name Enemy
extends CharacterBody2D


signal destroyed


const SPEED = 50.0
const MINIMUM_DISTANCE = 10.0
const MAX_PUSH_SPEED = 50.0
const PUSH_SPEED_THRESHOLD = 1.0
const CHASE_ACCELERATION = 40.0
const CHASE_SLOWDOWN = 5.0
const PUSH_DECAY = 10.0


var player: Player
var chase_velocity = Vector2.ZERO
var push_velocity = Vector2.ZERO


@onready var attack_cooldown_timer: Timer = %AttackCooldownTimer


func _physics_process(delta: float) -> void:
	if not player: return
	
	_apply_chase_velocity(delta)
	_apply_push_velocity()
	_decay_push_velocity(delta)
	move_and_slide()


func receive_push(direction: Vector2) -> void:
	push_velocity = direction * MAX_PUSH_SPEED
		

func _apply_chase_velocity(delta) -> void:
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
		hurtbox_owner.take_damage()
