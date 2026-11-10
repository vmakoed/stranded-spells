class_name SpellTakedown
extends Node2D


enum State { IDLE, PREVIEW, SPENT, RINGING }


const MANIFEST_DURATION = 0.2
const DISMISS_DURATION = 0.15
const PULSE_PERIOD = 1.0
const PULSE_SCALE = 1.1
const LINE_WIDTH = 1.0
const WAVE_COUNT = 3
const WAVE_INTERVAL = 0.1
const WAVE_DURATION = 0.35
const WAVE_RADIUS = 24.0
const WAVE_WIDTH = 1.0
const WAVE_COLOR = Color.TEAL
const WAVE_SEGMENTS = 32
const RING_SHAKE = 0.25
const RING_SHAKE_STEP = 0.05


var state := State.IDLE
var targets: Array[EnemyNew] = []
var _tween: Tween
var _base_scale := Vector2.ONE
var _wave_time := -1.0


@onready var bell: Sprite2D = %Bell


func _ready() -> void:
	_base_scale = bell.scale


func _process(delta: float) -> void:
	if _wave_time >= 0.0:
		_wave_time += delta
		queue_redraw()
	elif not targets.is_empty():
		queue_redraw()


func _draw() -> void:
	for enemy in targets:
		if not is_instance_valid(enemy): continue
		var to := to_local(enemy.hurtbox().global_position)
		draw_line(bell.position, to, enemy.stun_color(), LINE_WIDTH)
	if _wave_time < 0.0: return
	for i in WAVE_COUNT:
		var t := (_wave_time - i * WAVE_INTERVAL) / WAVE_DURATION
		if t < 0.0 or t > 1.0: continue
		var radius := WAVE_RADIUS * ease(t, 0.4)
		var color := Color(WAVE_COLOR, 1.0 - t)
		draw_arc(bell.position, radius, 0.0, TAU, WAVE_SEGMENTS, color, WAVE_WIDTH, false)


func set_targets(enemies: Array[EnemyNew]) -> void:
	if state != State.PREVIEW or enemies == targets: return
	targets = enemies
	queue_redraw()


func manifest() -> void:
	if state != State.IDLE: return
	state = State.PREVIEW
	_kill_tween()
	bell.scale = Vector2.ZERO
	modulate.a = 0.0

	_tween = create_tween()
	_tween \
		.tween_property(bell, "scale", _base_scale, MANIFEST_DURATION) \
		.set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)
	_tween \
		.parallel() \
		.tween_property(self, "modulate:a", 1.0, MANIFEST_DURATION)
	_tween.tween_callback(_start_pulse)


func dismiss() -> void:
	if state != State.PREVIEW: return
	state = State.SPENT
	_kill_tween()
	_vanish()


func ring() -> void:
	if state != State.PREVIEW: return
	state = State.RINGING
	targets = []
	_kill_tween()
	bell.scale = _base_scale
	modulate.a = 1.0
	_wave_time = 0.0

	_tween = create_tween()
	for angle in [RING_SHAKE, -RING_SHAKE, RING_SHAKE * 0.5, 0.0]:
		_tween \
			.tween_property(bell, "rotation", angle, RING_SHAKE_STEP) \
			.set_trans(Tween.TRANS_SINE)
	var waves_end := WAVE_INTERVAL * (WAVE_COUNT - 1) + WAVE_DURATION
	_tween.tween_interval(maxf(waves_end - RING_SHAKE_STEP * 4, 0.0))
	_tween.tween_callback(_vanish)


func _vanish() -> void:
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(bell, "scale", Vector2.ZERO, DISMISS_DURATION)
	_tween.tween_property(self, "modulate:a", 0.0, DISMISS_DURATION)
	_tween.finished.connect(queue_free)


func _start_pulse() -> void:
	_kill_tween()
	_tween = create_tween().set_loops()
	_tween \
		.tween_property(bell, "scale", _base_scale * PULSE_SCALE, PULSE_PERIOD / 2.0) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_IN_OUT)
	_tween \
		.tween_property(bell, "scale", _base_scale, PULSE_PERIOD / 2.0) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_IN_OUT)


func _kill_tween() -> void:
	if _tween: _tween.kill()
	_tween = null
