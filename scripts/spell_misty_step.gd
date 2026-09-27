class_name SpellMistyStep
extends Node2D


enum State { IDLE, PREVIEW, SPENT }


const MANIFEST_DURATION = 0.2
const DISMISS_DURATION = 0.15
const PULSE_PERIOD = 1.0
const PULSE_SCALE = 1.1


var state := State.IDLE
var _tween: Tween


@onready var visual: Node2D = %Visual
@onready var depart: CPUParticles2D = %Depart
@onready var arrive: CPUParticles2D = %Arrive


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


func release(from: Vector2, to: Vector2) -> void:
	if state == State.SPENT: return
	state = State.SPENT
	_kill_tween()
	visual.hide()
	depart.global_position = from
	arrive.global_position = to
	depart.restart()
	arrive.restart()
	await get_tree().create_timer(arrive.lifetime + 0.1).timeout
	if is_inside_tree(): queue_free()


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


func _kill_tween() -> void:
	if _tween: _tween.kill()
	_tween = null
