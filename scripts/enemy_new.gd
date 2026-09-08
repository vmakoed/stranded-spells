extends CharacterBody2D


signal died


enum State { CHASING, CHARGING, ATTACKING, RECHARGING, DEAD }


const CHASE_ACCELERATION = 40.0
const CHASE_SLOWDOWN = 5.0
const MAX_ATTACK_DISTANCE = 70.0
const SPEED = 30.0
const FACING_MIN_SPEED = 1.0
const CHARGE_SHAKE_DURATION = 0.9
const CHARGE_SHAKE_STRENGTH = 1.0
const CHARGE_SHAKE_STEP = 0.06
const DAMAGE_FLASH_DURATION = 1.0
const DEATH_GREYSCALE_DURATION = 0.5
const DEATH_FADE_DURATION = 0.5


@export var player: Player


var _attack_start_position: Vector2
var _charge_tween: Tween
var _damage_tween: Tween
var _death_tween: Tween
var _state: State: set = _set_state


func _ready() -> void:
	_state = State.CHASING


func _physics_process(delta: float) -> void:
	match _state:
		State.CHASING: _chase(delta)
		State.CHARGING: pass
		State.ATTACKING: _attack(delta)
		State.RECHARGING: _recharge(delta)
		State.DEAD: pass

	_update_facing()
	move_and_slide()


func _update_facing() -> void:
	if _state == State.DEAD:
		return
	if absf(velocity.x) < FACING_MIN_SPEED:
		return
	%Sprite2D.flip_h = velocity.x < 0.0


func _set_state(new_value: State) -> void:
	_state = new_value
	match _state:
		State.CHARGING:
			velocity = Vector2.ZERO
			_start_charge_shake()
		State.ATTACKING:
			_attack_start_position = global_position
			velocity = global_position.direction_to(player.global_position) * SPEED * 3.0
		State.RECHARGING:
			velocity = Vector2.ZERO
			%RechargeTimer.start()
		State.DEAD:
			velocity = Vector2.ZERO
			%RechargeTimer.stop()
			%AttackArea.set_deferred("monitoring", false)
			_start_death_animation()


func _chase(delta: float) -> void:
	if not is_instance_valid(player):
		return

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


func _start_charge_shake() -> void:
	if _charge_tween:
		_charge_tween.kill()

	var sprite: Node2D = %Sprite2D
	var origin := sprite.position
	_charge_tween = create_tween()
	_charge_tween.set_loops(int(CHARGE_SHAKE_DURATION / CHARGE_SHAKE_STEP))
	_charge_tween.tween_callback(func() -> void:
		sprite.position = origin + Vector2(
			randf_range(-CHARGE_SHAKE_STRENGTH, CHARGE_SHAKE_STRENGTH),
			randf_range(-CHARGE_SHAKE_STRENGTH, CHARGE_SHAKE_STRENGTH)
		)
	)
	_charge_tween.tween_interval(CHARGE_SHAKE_STEP)
	_charge_tween.finished.connect(func() -> void:
		sprite.position = origin
		_on_charge_finished()
	)


func _on_charge_finished() -> void:
	_state = State.ATTACKING


func _flash_damage() -> void:
	if _damage_tween:
		_damage_tween.kill()

	var flash_material: ShaderMaterial = %Sprite2D.material
	flash_material.set_shader_parameter("flash_amount", 1.0)
	_damage_tween = create_tween()
	_damage_tween.tween_property(
		flash_material,
		"shader_parameter/flash_amount",
		0.0,
		DAMAGE_FLASH_DURATION
	)


func _start_death_animation() -> void:
	if _charge_tween:
		_charge_tween.kill()
	if _damage_tween:
		_damage_tween.kill()

	var sprite: Node2D = %Sprite2D
	var flash_material: ShaderMaterial = sprite.material
	flash_material.set_shader_parameter("flash_amount", 0.0)
	flash_material.set_shader_parameter("greyscale_amount", 0.0)

	_death_tween = create_tween()
	_death_tween.tween_method(
		func(amount: float) -> void:
			flash_material.set_shader_parameter("greyscale_amount", amount),
		0.0,
		1.0,
		DEATH_GREYSCALE_DURATION
	)
	_death_tween.tween_property(
		sprite,
		"modulate:a",
		0.0,
		DEATH_FADE_DURATION
	)
	_death_tween.finished.connect(died.emit)


func _on_attack_area_body_entered(_body: Node2D) -> void:
	if not _state == State.CHASING:
		return

	_state = State.CHARGING


func _on_recharge_timer_timeout() -> void:
	if not %AttackArea.get_overlapping_bodies().is_empty():
		_state = State.CHARGING
	else:
		_state = State.CHASING


func _on_health_component_damaged(_value: float) -> void:
	_flash_damage()


func _on_health_component_health_below_minimum() -> void:
	_state = State.DEAD
