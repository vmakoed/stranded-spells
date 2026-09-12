class_name SpellAreaBurst
extends Area2D


enum State { IDLE, PREVIEW, BURSTING, SPENT }


const RADIUS = 32.0
const RING_TEXTURE_RADIUS = 61.0
const MANIFEST_DURATION = 0.2
const DISMISS_DURATION = 0.15
const PULSE_PERIOD = 1.0
const PULSE_SCALE = 1.06
const RELEASE_FLASH_DURATION = 0.12
const RELEASE_FLASH_SCALE = 1.15
const WAVE_DURATION = 0.25
const WAVE_FADE_DURATION = 0.15
const HIT_PAD = 8.0


var state := State.IDLE
var damage := 0.0
var _wave_radius := 0.0
var _hit: Array[int] = []
var _tween: Tween


@onready var visual: Node2D = %Visual
@onready var wave: Sprite2D = %Wave
@onready var burst: CPUParticles2D = %Burst


func _physics_process(_delta: float) -> void:
	if state != State.BURSTING: return
	_sweep()


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


func release(damage_value: float) -> void:
	if state != State.PREVIEW and state != State.IDLE: return
	state = State.BURSTING
	_kill_tween()
	damage = damage_value
	_hit.clear()
	_wave_radius = 0.0

	wave.scale = Vector2.ZERO
	wave.modulate.a = 1.0
	wave.show()
	burst.restart()

	_tween = create_tween() \
		.set_parallel(true) \
		.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_tween.tween_property(visual, "scale", Vector2.ONE * RELEASE_FLASH_SCALE, RELEASE_FLASH_DURATION)
	_tween.tween_property(visual, "modulate:a", 0.0, RELEASE_FLASH_DURATION)
	_tween \
		.tween_method(_set_wave_radius, 0.0, RADIUS, WAVE_DURATION) \
		.set_trans(Tween.TRANS_CUBIC) \
		.set_ease(Tween.EASE_OUT)
	_tween \
		.tween_property(wave, "modulate:a", 0.0, WAVE_FADE_DURATION) \
		.set_delay(WAVE_DURATION)
	_tween.finished.connect(_finish)

	_sweep()


func dismiss() -> void:
	if state != State.PREVIEW: return
	state = State.SPENT
	_kill_tween()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(visual, "scale", Vector2.ZERO, DISMISS_DURATION)
	_tween.tween_property(visual, "modulate:a", 0.0, DISMISS_DURATION)
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


func _set_wave_radius(radius: float) -> void:
	_wave_radius = radius
	wave.scale = Vector2.ONE * (radius / RING_TEXTURE_RADIUS)


func _sweep() -> void:
	for area in get_overlapping_areas():
		if area is not HurtboxComponent: continue
		var id := area.get_instance_id()
		if id in _hit: continue
		if global_position.distance_to(area.global_position) > _wave_radius + HIT_PAD: continue
		area.damage(damage, true)
		_hit.append(id)


func _finish() -> void:
	if state != State.BURSTING: return
	_wave_radius = RADIUS
	_sweep()
	state = State.SPENT
	set_deferred(&"monitoring", false)
	wave.hide()
	visual.hide()
	await get_tree().create_timer(burst.lifetime + 0.1).timeout
	if is_inside_tree(): queue_free()


func _kill_tween() -> void:
	if _tween: _tween.kill()
	_tween = null
