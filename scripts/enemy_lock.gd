class_name EnemyLock
extends Node2D


const KEY_TEXTURE := preload("res://assets/textures/xtra icons 190.png")
const KEY_OFFSET := Vector2(0, -18)
const KEY_DOCK_OFFSET := Vector2(0, -11)
const KEY_QUEUE_SPACING := Vector2(-12, 0)
const RING_RADIUS := 5.0
const BOB_HEIGHT := 1.5
const BOB_SPEED := 4.0
const FLY_DURATION := 0.6
const FLY_ARC_HEIGHT := 24.0
const QUEUE_SLIDE_DURATION := 0.15
const FILL_DURATION := 0.6
const POP_DURATION := 0.2
const RING_FADE_DURATION := 0.3


@export var enemies: Array[EnemyNew] = []
@export var door: ChallengeDoor
@export var key_texture: Texture2D = KEY_TEXTURE


var _ring: ProgressRing
var _attached := {}
var _queue: Array[Sprite2D] = []
var _busy := false
var _filled := 0
var _total := 0
var _time := 0.0


func _ready() -> void:
	if door == null: return
	door.closed = true
	_ring = ProgressRing.new()
	_ring.radius = RING_RADIUS
	add_child(_ring)
	_ring.global_position = door.global_position

	for enemy in enemies:
		if not is_instance_valid(enemy): continue
		var key := _make_key()
		_attached[key] = enemy
		enemy.died.connect(_on_enemy_died.bind(key), CONNECT_ONE_SHOT)
		_total += 1
	if _total == 0: _unlock()


func _process(delta: float) -> void:
	_time += delta
	var bob := Vector2(0, sin(_time * BOB_SPEED) * BOB_HEIGHT)
	for key: Sprite2D in _attached:
		var enemy: EnemyNew = _attached[key]
		if is_instance_valid(enemy):
			key.global_position = enemy.global_position + KEY_OFFSET + bob


func _make_key() -> Sprite2D:
	var key := Sprite2D.new()
	key.texture = key_texture
	key.z_index = 3
	var unshaded := CanvasItemMaterial.new()
	unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	key.material = unshaded
	add_child(key)
	return key


func _on_enemy_died(key: Sprite2D) -> void:
	_attached.erase(key)
	var from := key.global_position
	var to := _slot_position(_queue.size() + (1 if _busy else 0))
	var control := (from + to) / 2 + Vector2(0, -FLY_ARC_HEIGHT)
	var tween := create_tween()
	tween.tween_method(_fly_step.bind(key, from, control, to), 0.0, 1.0, FLY_DURATION) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	_queue.append(key)
	_slide_queue()
	_pump()


func _fly_step(t: float, key: Sprite2D, from: Vector2, control: Vector2, to: Vector2) -> void:
	key.global_position = from.lerp(control, t).lerp(control.lerp(to, t), t)


func _pump() -> void:
	if _busy or _queue.is_empty(): return
	_busy = true
	var key: Sprite2D = _queue.pop_front()
	_slide_queue()

	var tween := create_tween()
	tween.tween_property(key, "global_position", _slot_position(0), QUEUE_SLIDE_DURATION)
	tween.tween_property(_ring, "value", float(_filled + 1) / _total, FILL_DURATION)
	tween.tween_property(key, "scale", Vector2.ZERO, POP_DURATION) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(key, "modulate:a", 0.0, POP_DURATION)
	await tween.finished
	key.queue_free()
	_filled += 1
	_busy = false

	if _filled >= _total:
		_unlock()
	else:
		_pump()


func _slide_queue() -> void:
	var offset := 1 if _busy else 0
	for i in _queue.size():
		var slot := _slot_position(i + offset)
		create_tween().tween_property(_queue[i], "global_position", slot, QUEUE_SLIDE_DURATION)


func _slot_position(index: int) -> Vector2:
	return _ring.global_position + KEY_DOCK_OFFSET + KEY_QUEUE_SPACING * index


func _unlock() -> void:
	door.open()
	var tween := create_tween()
	tween.tween_property(_ring, "modulate:a", 0.0, RING_FADE_DURATION)
	await tween.finished
	queue_free()
