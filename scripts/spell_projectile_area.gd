class_name SpellProjectile
extends Area2D


enum State { IDLE, PREVIEW, FLYING, DEFLECTED, SPENT }


const MANIFEST_DURATION = 0.2
const DISMISS_DURATION = 0.15
const PULSE_PERIOD = 1.0
const PULSE_SCALE = 1.12
const DEFLECT_SPEED_SCALE = 0.6
const DEFLECT_FADE_DURATION = 0.3
const DEFLECT_END_SCALE = 0.4
const WORLD_LAYER = 3


@export var damage := 50.0
@export var breaks_shield := false
@export var ignites_torches := false


var state := State.IDLE
var velocity := Vector2.ZERO
var _tween: Tween


@onready var visual: Node2D = %Visual
@onready var trail: CPUParticles2D = %Trail


func _physics_process(delta: float) -> void:
	if state != State.FLYING and state != State.DEFLECTED: return
	position += velocity * delta


func manifest() -> void:
	if state != State.IDLE: return
	state = State.PREVIEW
	_kill_tween()
	visual.scale = Vector2.ZERO
	visual.modulate.a = 0.0

	_tween = create_tween()
	_tween \
		.tween_property(visual, "scale", Vector2.ONE, MANIFEST_DURATION) \
		.set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)
	_tween \
		.parallel() \
		.tween_property(visual, "modulate:a", 1.0, MANIFEST_DURATION)
	_tween.tween_callback(_start_pulse)


func launch(direction: Vector2, speed: float) -> void:
	if state != State.PREVIEW and state != State.IDLE: return
	state = State.FLYING
	_kill_tween()
	visual.scale = Vector2.ONE
	visual.modulate.a = 1.0
	velocity = direction * speed
	rotation = direction.angle()
	trail.emitting = true
	for area in get_overlapping_areas():
		if _try_hit(area): return
	for body in get_overlapping_bodies():
		if _try_hit_wall(body): return


func dismiss() -> void:
	if state != State.PREVIEW: return
	state = State.SPENT
	_kill_tween()
	_tween = create_tween()
	_tween.tween_property(visual, "scale", Vector2.ZERO, DISMISS_DURATION)
	_tween.parallel().tween_property(visual, "modulate:a", 0.0, DISMISS_DURATION)
	_tween.finished.connect(queue_free)


func _start_pulse() -> void:
	_kill_tween()
	_tween = create_tween().set_loops()
	_tween \
		.tween_property(visual, "scale", Vector2.ONE * PULSE_SCALE, PULSE_PERIOD / 2.0) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_IN_OUT)
	_tween \
		.tween_property(visual, "scale", Vector2.ONE, PULSE_PERIOD / 2.0) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_IN_OUT)


func _spend() -> void:
	if state != State.FLYING: return
	_finish()


func _deflect(area: Area2D) -> void:
	state = State.DEFLECTED
	var normal := global_position - area.global_position
	if normal.is_zero_approx(): normal = -velocity
	velocity = velocity.bounce(normal.normalized()) * DEFLECT_SPEED_SCALE
	rotation = velocity.angle()

	_kill_tween()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(visual, "modulate:a", 0.0, DEFLECT_FADE_DURATION)
	_tween.tween_property(visual, "scale", Vector2.ONE * DEFLECT_END_SCALE, DEFLECT_FADE_DURATION)
	_tween.finished.connect(_finish)


func _finish() -> void:
	if state == State.SPENT: return
	state = State.SPENT
	velocity = Vector2.ZERO
	_kill_tween()
	set_deferred(&"monitoring", false)
	visual.hide()
	trail.emitting = false
	await get_tree().create_timer(trail.lifetime + 0.1).timeout
	if is_inside_tree(): queue_free()


func _try_hit(area: Area2D) -> bool:
	if area is Torch:
		if ignites_torches: area.ignite()
		return false
	if area is not HurtboxComponent: return false
	if area.damage(damage, breaks_shield):
		_deflect(area)
	else:
		_spend()
	return true


func _try_hit_wall(body: Node2D) -> bool:
	if not _is_world(body): return false
	if ignites_torches:
		for area in get_overlapping_areas():
			if area is Torch: area.ignite()
	_spend()
	return true


func _is_world(body: Node2D) -> bool:
	if body is TileMapLayer: return true
	if body is PhysicsBody2D: return body.get_collision_layer_value(WORLD_LAYER)
	return false


func _kill_tween() -> void:
	if _tween: _tween.kill()
	_tween = null


func _on_area_entered(area: Area2D) -> void:
	if state != State.FLYING: return
	_try_hit(area)


func _on_body_entered(body: Node2D) -> void:
	match state:
		State.FLYING: _try_hit_wall(body)
		State.DEFLECTED: if _is_world(body): _finish()


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	if state != State.FLYING and state != State.DEFLECTED: return
	_finish()
