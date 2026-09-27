class_name EnemySkeleton
extends EnemyNew


const ATTACK_ANIMATION := &"attack"
const SLASH_FRAMES: Array[int] = [7]
const HITBOX_OFFSET := 9.0


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


func _attack(_delta: float) -> void:
	pass


func _swing() -> void:
	_face_player()
	%Sprite2D.stop()
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
	%HitboxComponent.set_deferred("monitoring", %Sprite2D.frame in SLASH_FRAMES)


func _on_sprite_animation_finished() -> void:
	if _state != State.ATTACKING:
		return
	if _can_start_attack():
		_swing()
	else:
		_state = State.CHASING
