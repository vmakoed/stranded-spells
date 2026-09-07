extends CharacterBody2D


enum State { CHASING, CHARGING, ATTACKING, RECHARGING }


const CHASE_ACCELERATION = 40.0
const CHASE_SLOWDOWN = 5.0
const MAX_ATTACK_DISTANCE = 70.0
const SPEED = 30.0


@export var player: Player


var _attack_start_position: Vector2
var _state: State: set = _set_state


func _ready() -> void:
	_state = State.CHASING


func _physics_process(delta: float) -> void:
	match _state:
		State.CHASING: _chase(delta)
		# State.CHARGING: _charge(delta)
		State.ATTACKING: _attack(delta)
		State.RECHARGING: _recharge(delta)		

	move_and_slide()


func _set_state(new_value: State) -> void:
	print(new_value)
	_state = new_value
	match _state:
		State.ATTACKING:
			_attack_start_position = global_position
			velocity = global_position.direction_to(player.global_position) * SPEED * 3.0
		State.RECHARGING:
			velocity = Vector2.ZERO
			%RechargeTimer.start()


func _chase(delta: float) -> void:
	velocity = lerp(
		velocity, 
		global_position.direction_to(player.global_position) * SPEED, 
		delta * CHASE_ACCELERATION
	)


func _attack(_delta: float) -> void:
	if _is_attack_finished() or is_on_wall(): 
		_state = State.RECHARGING


func _recharge(_delta: float) -> void:
	pass


func _is_attack_finished() -> bool:
	return _attack_start_position.distance_to(global_position) >= MAX_ATTACK_DISTANCE


func _on_attack_area_body_entered(body: Node2D) -> void:
	if not _state == State.CHASING:
		return

	_state = State.ATTACKING


func _on_recharge_timer_timeout() -> void:
	if not %AttackArea.get_overlapping_bodies().is_empty():
		_state = State.ATTACKING
	else:
		_state = State.CHASING
