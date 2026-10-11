class_name DoorLock
extends Node2D


const RING_RADIUS := 5.0
const FILL_DURATION := 0.6
const RING_FADE_DURATION := 0.3


@export var switches: Array[Switch] = []
@export var plates: Array[PressurePlate] = []
@export var door: ChallengeDoor


var _ring: ProgressRing
var _pending := 0
var _busy := false
var _filled := 0
var _total := 0


func _ready() -> void:
	if door == null: return
	door.closed = true
	_ring = ProgressRing.new()
	_ring.radius = RING_RADIUS
	add_child(_ring)
	_ring.global_position = door.global_position

	for s in switches:
		if not is_instance_valid(s): continue
		s.activated.connect(_on_activated, CONNECT_ONE_SHOT)
		_total += 1
	for p in plates:
		if not is_instance_valid(p): continue
		p.pressed.connect(_on_activated, CONNECT_ONE_SHOT)
		_total += 1
	if _total == 0: _unlock()


func _on_activated() -> void:
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
