class_name DoorLock
extends Node2D


const RING_RADIUS := 5.0
const FILL_DURATION := 0.6
const RING_FADE_DURATION := 0.3


@export var switches: Array[Switch] = []
@export var plates: Array[PressurePlate] = []
@export var doors: Array[ChallengeDoor] = []
@export var save_id := ""


var _rings: Array[ProgressRing] = []
var _sources: Array = []
var _queue: Array[int] = []
var _active := -1
var _solved: Array[int] = []
var _tween: Tween
var _filled := 0
var _total := 0


func _ready() -> void:
	doors.assign(doors.filter(is_instance_valid))
	if doors.is_empty(): return
	var solved: Array = GameState.get_flag(self, [])
	_sources.append_array(switches)
	_sources.append_array(plates)
	for i in _sources.size():
		var source: Node = _sources[i]
		if not is_instance_valid(source): continue
		_total += 1
		if i in solved:
			_filled += 1
			if source is Switch: source.on = true
			else: source.latched = true
			continue
		if source is Switch:
			source.activated.connect(_enqueue.bind(i), CONNECT_ONE_SHOT)
		else:
			source.pressed.connect(_enqueue.bind(i))
			source.released.connect(_on_plate_released.bind(i))
	if _filled >= _total:
		for door in doors: door.closed = false
		queue_free()
		return

	for door in doors:
		door.closed = true
		var ring := ProgressRing.new()
		ring.radius = RING_RADIUS
		add_child(ring)
		ring.global_position = door.global_position
		ring.value = float(_filled) / _total
		_rings.append(ring)


func _enqueue(index: int) -> void:
	if index == _active or index in _queue or index in _solved: return
	_queue.append(index)
	_pump()


func _on_plate_released(index: int) -> void:
	if index != _active:
		_queue.erase(index)
		return
	_tween.kill()
	_active = -1
	for ring in _rings: ring.value = float(_filled) / _total
	_pump()


func _pump() -> void:
	if _active != -1 or _queue.is_empty(): return
	_active = _queue.pop_front()
	_tween = create_tween().set_parallel()
	for ring in _rings:
		_tween.tween_property(ring, "value", float(_filled + 1) / _total, FILL_DURATION)
	_tween.finished.connect(_on_fill_finished)


func _on_fill_finished() -> void:
	var source: Node = _sources[_active]
	if source is PressurePlate: source.latched = true
	_solved.append(_active)
	var solved: Array = GameState.get_flag(self, []).duplicate()
	solved.append(_active)
	GameState.set_flag(self, solved)
	_active = -1
	_filled += 1
	if _filled >= _total:
		_unlock()
	else:
		_pump()


func _unlock() -> void:
	for door in doors: door.open()
	var tween := create_tween().set_parallel()
	for ring in _rings:
		tween.tween_property(ring, "modulate:a", 0.0, RING_FADE_DURATION)
	await tween.finished
	queue_free()
