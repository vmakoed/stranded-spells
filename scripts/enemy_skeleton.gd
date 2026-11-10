class_name EnemySkeleton
extends EnemyNew


const CHARGE_ANIMATION := &"charge"
const ATTACK_ANIMATION := &"attack"
const SLASH_FRAMES: Array[int] = [1]
const HITBOX_OFFSET := 9.0
const LUNGE_SPEED := 120.0
const LUNGE_DECEL := 600.0


var _lunge_direction: Vector2


func _begin_attack() -> void:
	_state = State.ATTACKING


func _set_state(new_value: State) -> void:
	if new_value != State.ATTACKING:
		if _state == State.ATTACKING and new_value != State.DEAD:
			_end_swing()
		super(new_value)
		return
	_state = new_value
	velocity = Vector2.ZERO
	_swing()


func _attack(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, LUNGE_DECEL * delta)


func _swing() -> void:
	_face_player()
	%Sprite2D.stop()
	%Sprite2D.play(CHARGE_ANIMATION)


func _strike() -> void:
	_face_player()
	_lunge_direction = global_position.direction_to(player.global_position) if is_instance_valid(player) else Vector2.ZERO
	velocity = _lunge_direction * LUNGE_SPEED
	%Sprite2D.play(ATTACK_ANIMATION)


func _end_swing() -> void:
	%HitboxComponent.set_deferred("monitoring", false)


func _face_player() -> void:
	if not is_instance_valid(player):
		return
	var sprite: AnimatedSprite2D = %Sprite2D
	sprite.flip_h = player.global_position.x < global_position.x
	%HitboxComponent.position.x = -HITBOX_OFFSET if sprite.flip_h else HITBOX_OFFSET


func _on_sprite_frame_changed() -> void:
	if _state != State.ATTACKING:
		return
	var sprite: AnimatedSprite2D = %Sprite2D
	%HitboxComponent.set_deferred("monitoring", sprite.animation == ATTACK_ANIMATION and sprite.frame in SLASH_FRAMES)


func _on_sprite_animation_finished() -> void:
	if _state != State.ATTACKING:
		return
	if %Sprite2D.animation == CHARGE_ANIMATION:
		_strike()
	else:
		_state = State.RECHARGING
