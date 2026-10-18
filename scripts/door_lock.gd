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
var _pending := 0
var _busy := false
var _filled := 0
var _total := 0


func _ready() -> void:
	doors.assign(doors.filter(is_instance_valid))
	if doors.is_empty(): return
	var solved: Array = GameState.get_flag(self, [])
	var sources: Array = []
	sources.append_array(switches)
	sources.append_array(plates)
	for i in sources.size():
		var source: Node = sources[i]
		if not is_instance_valid(source): continue
		_total += 1
		if i in solved:
			_filled += 1
			if source is Switch: source.on = true
			continue
		var done: Signal = source.activated if source is Switch else source.pressed
		done.connect(_on_activated.bind(i), CONNECT_ONE_SHOT)
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


func _on_activated(index: int) -> void:
	var solved: Array = GameState.get_flag(self, []).duplicate()
	solved.append(index)
	GameState.set_flag(self, solved)
	_pending += 1
	_pump()


func _pump() -> void:
	if _busy or _pending == 0: return
	_busy = true
	_pending -= 1
	var tween := create_tween().set_parallel()
	for ring in _rings:
		tween.tween_property(ring, "value", float(_filled + 1) / _total, FILL_DURATION)
	await tween.finished
	_filled += 1
	_busy = false

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
