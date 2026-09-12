class_name SpellHeal
extends Node2D


## Inverse of SpellAreaBurst: ring appears around the target, shrinks inward, and emits
## `arrived` when it reaches the centre. The owner decides what "arrived" does (heal).
signal arrived


enum State { IDLE, PREVIEW, CONVERGING, SPENT }


const RADIUS = 32.0
const RING_TEXTURE_RADIUS = 61.0
const MANIFEST_DURATION = 0.2
const DISMISS_DURATION = 0.15
const PULSE_PERIOD = 1.0
const PULSE_SCALE = 1.06
const RELEASE_FADE_DURATION = 0.12
const CONVERGE_DURATION = 0.3


var state := State.IDLE
var target: Node2D
var _tween: Tween


@onready var visual: Node2D = %Visual
@onready var wave: Sprite2D = %Wave
@onready var sparkle: CPUParticles2D = %Sparkle


func _process(_delta: float) -> void:
	if state == State.SPENT: return
	if not is_instance_valid(target): return
	global_position = target.global_position


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


func release() -> void:
	if state != State.PREVIEW and state != State.IDLE: return
	state = State.CONVERGING
	_kill_tween()

	_set_wave_radius(RADIUS)
	wave.modulate.a = 1.0
	wave.show()

	_tween = create_tween().set_parallel(true)
	_tween.tween_property(visual, "modulate:a", 0.0, RELEASE_FADE_DURATION)
	_tween \
		.tween_method(_set_wave_radius, RADIUS, 0.0, CONVERGE_DURATION) \
		.set_trans(Tween.TRANS_CUBIC) \
		.set_ease(Tween.EASE_IN)
	_tween.finished.connect(_arrive)


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
	wave.scale = Vector2.ONE * (radius / RING_TEXTURE_RADIUS)


func _arrive() -> void:
	if state != State.CONVERGING: return
	state = State.SPENT
	wave.hide()
	visual.hide()
	sparkle.restart()
	arrived.emit()
	await get_tree().create_timer(sparkle.lifetime + 0.1).timeout
	if is_inside_tree(): queue_free()


func _kill_tween() -> void:
	if _tween: _tween.kill()
	_tween = null
