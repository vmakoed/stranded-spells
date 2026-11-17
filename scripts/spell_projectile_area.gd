class_name SpellProjectile
extends Area2D


signal spent


enum State { IDLE, PREVIEW, FLYING, SPENT }


const MANIFEST_DURATION = 0.2
const DISMISS_DURATION = 0.15
const PULSE_PERIOD = 1.0
const PULSE_SCALE = 1.12
const WORLD_LAYER = 3
const ENEMY_LAYER = 4
const PLAYER_HURTBOX_LAYER = 5


@export var damage := 50.0
@export var stun_damage := 0.0
@export var ignites_torches := false
@export var toggles_switches := false
@export var homing_turn_rate := 0.0
@export var blocks_spells := false


var state := State.IDLE
var velocity := Vector2.ZERO
var homing_target: Node2D
var return_target: Node2D
var _tween: Tween
var _hit := false


@onready var visual: Node2D = %Visual
@onready var trail: CPUParticles2D = %Trail


func _physics_process(delta: float) -> void:
	if state != State.FLYING: return
	if homing_target != null: _home(delta)
	position += velocity * delta


func _home(delta: float) -> void:
	if not AimAssist.is_valid(homing_target):
		homing_target = null
		return
	var angle := velocity.angle_to(homing_target.global_position - global_position)
	if absf(angle) > PI / 2.0:
		homing_target = null
		return
	velocity = velocity.rotated(clampf(angle, -homing_turn_rate * delta, homing_turn_rate * delta))
	rotation = velocity.angle()


func manifest() -> void:
	if state != State.IDLE: return
	state = State.PREVIEW
	if blocks_spells: set_deferred(&"collision_layer", 1 << (ENEMY_LAYER - 1))
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
	if blocks_spells: set_deferred(&"collision_layer", 0)
	_kill_tween()
	visual.scale = Vector2.ONE
	visual.modulate.a = 1.0
	velocity = direction * speed
	rotation = direction.angle()
	trail.emitting = true
	_sweep_after_launch()


func _sweep_after_launch() -> void:
	await get_tree().physics_frame
	if state != State.FLYING or _hit: return
	for area in get_overlapping_areas():
		if _try_hit(area): return
	for body in get_overlapping_bodies():
		if _try_hit_wall(body): return


func dismiss() -> void:
	if state != State.PREVIEW: return
	state = State.SPENT
	if blocks_spells: set_deferred(&"collision_layer", 0)
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
	homing_target = null
	var shield := (area as HurtboxComponent).shield_component
	velocity = shield.deflect(velocity)
	if shield.direction != Vector2.ZERO:
		var offset := (global_position - area.global_position).length()
		global_position = area.global_position + velocity.normalized() * offset
	rotation = velocity.angle()
	if AimAssist.is_valid(return_target):
		var to_target := return_target.global_position - global_position
		if absf(velocity.angle_to(to_target)) <= AimAssist.CONE:
			homing_target = return_target
	return_target = null
	var mask := collision_mask | 1 << (ENEMY_LAYER - 1) | 1 << (PLAYER_HURTBOX_LAYER - 1)
	set_deferred(&"collision_mask", mask)


func _finish() -> void:
	if state == State.SPENT: return
	state = State.SPENT
	velocity = Vector2.ZERO
	_kill_tween()
	set_deferred(&"monitoring", false)
	visual.hide()
	trail.emitting = false
	spent.emit()
	await get_tree().create_timer(trail.lifetime + 0.1).timeout
	if is_inside_tree(): queue_free()


func _try_hit(area: Area2D) -> bool:
	if area is Torch:
		if ignites_torches: area.ignite()
		return false
	if area is SpellProjectile:
		if not area.blocks_spells or area.state != State.PREVIEW: return false
		_hit = true
		_spend()
		return true
	if area is not HurtboxComponent: return false
	_hit = true
	if area.damage(damage, stun_damage):
		_deflect(area)
	else:
		_spend()
	return true


func _try_hit_wall(body: Node2D) -> bool:
	if not _is_world(body): return false
	_hit = true
	if body is Switch and toggles_switches: body.activate()
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
	if state != State.FLYING: return
	_try_hit_wall(body)


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	if state != State.FLYING: return
	_spend()
