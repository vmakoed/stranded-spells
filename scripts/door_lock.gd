class_name DoorLock
extends Node2D


const RING_RADIUS := 5.0
const FILL_DURATION := 0.6
const RING_FADE_DURATION := 0.3


@export var switches: Array[Switch] = []
@export var plates: Array[PressurePlate] = []
@export var door: ChallengeDoor
@export var save_id := ""


var _ring: ProgressRing
var _pending := 0
var _busy := false
var _filled := 0
var _total := 0


func _ready() -> void:
	if door == null: return
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
		door.closed = false
		queue_free()
		return

	door.closed = true
	_ring = ProgressRing.new()
	_ring.radius = RING_RADIUS
	add_child(_ring)
	_ring.global_position = door.global_position
	_ring.value = float(_filled) / _total


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
	var tween := create_tween()
	tween.tween_property(_ring, "value", float(_filled + 1) / _total, FILL_DURATION)
	await tween.finished
	_filled += 1
	_busy = false

	if _filled >= _total:
		_unlock()
	else:
		_pump()


func _unlock() -> void:
	door.open()
	var tween := create_tween()
	tween.tween_property(_ring, "modulate:a", 0.0, RING_FADE_DURATION)
	await tween.finished
	queue_free()
