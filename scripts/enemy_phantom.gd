class_name EnemyPhantom
extends EnemyRanged


const FADE_TIME = 0.15
const APPEAR_TRIES = 12
const APPEAR_MASK = 1 << 2
const HOLD_OFFSET = 18.0


@export var hidden_time_min := 0.8
@export var hidden_time_max := 1.6
@export var visible_time := 2.5
@export var appear_distance_min := 56.0
@export var appear_distance_max := 96.0


var _hidden := false
var _appear_point: Vector2
var _body_layer: int
var _fade_tween: Tween
var _shot: SpellProjectile


func _ready() -> void:
	shielded = false
	_body_layer = collision_layer
	super()


func aim_node() -> Node2D:
	if _hidden:
		return null
	if _is_holding_shot():
		return _shot
	return hurtbox()


func _set_state(new_value: State) -> void:
	if _state == State.CHARGING and new_value != State.ATTACKING and _is_holding_shot():
		_shot.dismiss()
	match new_value:
		State.CHASING:
			%AimLine.hide()
			_state = new_value
			velocity = Vector2.ZERO
			_vanish()
			%RechargeTimer.start(randf_range(hidden_time_min, hidden_time_max))
		State.CHARGING:
			global_position = _appear_point
			_appear()
			_hold_shot()
			super(new_value)
		State.RECHARGING:
			_state = new_value
			velocity = Vector2.ZERO
			%RechargeTimer.start(visible_time)
		_:
			super(new_value)


func _chase(_delta: float) -> void:
	velocity = Vector2.ZERO


func _recharge(_delta: float) -> void:
	velocity = Vector2.ZERO


func _can_start_attack() -> bool:
	if not is_instance_valid(player):
		return false
	var space := get_world_2d().direct_space_state
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = $CollisionShape2D.shape
	query.collision_mask = APPEAR_MASK
	for i in APPEAR_TRIES:
		var offset := Vector2.from_angle(randf() * TAU) * randf_range(appear_distance_min, appear_distance_max)
		var point := player.global_position + offset
		query.transform = Transform2D(0.0, point)
		if not space.intersect_shape(query, 1).is_empty():
			continue
		var ray := PhysicsRayQueryParameters2D.create(point, player.global_position, SIGHT_MASK)
		if not space.intersect_ray(ray).is_empty():
			continue
		_appear_point = point
		return true
	return false


func _hold_shot() -> void:
	_shot = projectile_scene.instantiate()
	_shot.top_level = true
	add_child(_shot)
	_shot.global_position = global_position
	_shot.return_target = hurtbox()
	_shot.spent.connect(_on_shot_spent.bind(_shot))
	_shot.manifest()


func _is_holding_shot() -> bool:
	return is_instance_valid(_shot) and _shot.state == SpellProjectile.State.PREVIEW


func _update_aim() -> void:
	super()
	if not _is_holding_shot():
		return
	_shot.global_position = global_position + _attack_direction * HOLD_OFFSET
	_shot.rotation = _attack_direction.angle()


func _fire() -> SpellProjectile:
	_shot.launch(_attack_direction, projectile_speed)
	return _shot


func _vanish() -> void:
	if _hidden:
		return
	_hidden = true
	_fade(0.0)
	hurtbox().set_deferred(&"monitorable", false)
	set_deferred(&"collision_layer", 0)


func _appear() -> void:
	_hidden = false
	_fade(1.0)
	hurtbox().set_deferred(&"monitorable", true)
	set_deferred(&"collision_layer", _body_layer)


func _fade(alpha: float) -> void:
	if _fade_tween:
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(%Sprite2D, "modulate:a", alpha, FADE_TIME)


func _on_shot_spent(shot: SpellProjectile) -> void:
	if shot == _shot and _state == State.RECHARGING:
		_state = State.CHASING


func _on_health_component_damaged(value: float) -> void:
	super(value)
	_vanish_after_hit.call_deferred()


func _vanish_after_hit() -> void:
	if _state in [State.CHARGING, State.ATTACKING, State.RECHARGING]:
		_state = State.CHASING


func _on_recharge_timer_timeout() -> void:
	match _state:
		State.CHASING:
			if _can_start_attack():
				_begin_attack()
			else:
				%RechargeTimer.start(randf_range(hidden_time_min, hidden_time_max))
		State.RECHARGING:
			_state = State.CHASING
