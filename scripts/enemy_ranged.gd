class_name EnemyRanged
extends EnemyNew


const AIM_LINE_LENGTH = 240.0
const BLINK_COUNT = 3
const BLINK_STEP = 0.08
const SPAWN_OFFSET = 8.0
const SIGHT_MASK = 4


@export var keep_distance_min := 48.0
@export var keep_distance_max := 80.0
@export var attack_range := 120.0
@export var aim_time := 0.8
@export var projectile_speed := 150.0
@export var projectile_scene: PackedScene = preload("res://scenes/enemy_projectile.tscn")


var _aim_locked := false


func _physics_process(delta: float) -> void:
	if _state == State.CHARGING and not _aim_locked:
		_update_aim()
	super(delta)


func _set_state(new_value: State) -> void:
	if _state == State.CHARGING and new_value != State.CHARGING:
		%AimLine.hide()
	match new_value:
		State.CHARGING:
			_state = new_value
			velocity = Vector2.ZERO
			_start_aim()
		State.ATTACKING:
			_state = new_value
			_fire()
			_set_state(State.RECHARGING)
		_:
			super(new_value)


func _chase(delta: float) -> void:
	_reposition(delta)
	if _can_start_attack():
		_begin_attack()


func _recharge(delta: float) -> void:
	_reposition(delta)


func _reposition(delta: float) -> void:
	if not is_instance_valid(player):
		return
	var to_player := player.global_position - global_position
	var distance := to_player.length()
	var target := Vector2.ZERO
	if distance < keep_distance_min:
		target = -to_player.normalized() * SPEED
	elif distance > keep_distance_max:
		target = to_player.normalized() * SPEED
	velocity = lerp(velocity, target, delta * CHASE_ACCELERATION)


func _can_start_attack() -> bool:
	if not is_instance_valid(player):
		return false
	if global_position.distance_to(player.global_position) > attack_range:
		return false
	return _cast_sight(player.global_position).is_empty()


func _cast_sight(target: Vector2) -> Dictionary:
	var query := PhysicsRayQueryParameters2D.create(global_position, target, SIGHT_MASK)
	return get_world_2d().direct_space_state.intersect_ray(query)


func _update_facing() -> void:
	if _state == State.CHARGING and is_instance_valid(player):
		%Sprite2D.flip_h = player.global_position.x < global_position.x
		return
	super()


func _start_aim() -> void:
	if _charge_tween:
		_charge_tween.kill()

	_aim_locked = false
	_update_aim()
	var line: Line2D = %AimLine
	line.show()

	_charge_tween = create_tween()
	_charge_tween.tween_interval(aim_time)
	_charge_tween.tween_callback(func() -> void: _aim_locked = true)
	for i in BLINK_COUNT:
		_charge_tween.tween_callback(line.hide)
		_charge_tween.tween_interval(BLINK_STEP)
		_charge_tween.tween_callback(line.show)
		_charge_tween.tween_interval(BLINK_STEP)
	_charge_tween.tween_callback(line.hide)
	_charge_tween.tween_callback(_on_charge_finished)


func _update_aim() -> void:
	if not is_instance_valid(player):
		return
	_attack_direction = global_position.direction_to(player.global_position)
	var end := global_position + _attack_direction * AIM_LINE_LENGTH
	var hit := _cast_sight(end)
	if not hit.is_empty():
		end = hit.position
	%AimLine.points = PackedVector2Array([Vector2.ZERO, to_local(end)])


func _fire() -> void:
	var projectile: SpellProjectile = projectile_scene.instantiate()
	projectile.top_level = true
	add_child(projectile)
	projectile.global_position = global_position + _attack_direction * SPAWN_OFFSET
	projectile.launch(_attack_direction, projectile_speed)


func _on_attack_area_body_entered(_body: Node2D) -> void:
	start_chase()
