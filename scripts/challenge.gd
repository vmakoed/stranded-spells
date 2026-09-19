class_name Challenge
extends Area2D


signal started
signal completed
signal failed


const ENEMY_SCENE := preload("res://scenes/enemy_new.tscn")
const FAIL_FADE_IN := 0.2
const FAIL_HOLD := 0.2
const FAIL_FADE_OUT := 0.2


@export var spawn_points: Array[Marker2D] = []
@export var doors: Array[ChallengeDoor] = []
@export var respawn_point: Marker2D
@export var shielded := true


var _player: Player
var _spawned: Array[EnemyNew] = []
var _pending: Array[EnemyNew] = []
var _triggered := false
var _completed := false
var _fade: ScreenFade


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_on_body_entered)
	_fade = ScreenFade.new()
	add_child(_fade)


func complete() -> void:
	if _completed: return
	_completed = true
	_clear_respawn()
	_open_doors()
	completed.emit()
	queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body is not Player or _triggered: return
	_triggered = true
	_player = body
	set_deferred("monitoring", false)
	_start.call_deferred()


func _start() -> void:
	for point in spawn_points:
		if is_instance_valid(point): _spawn(point)

	for door in doors:
		if is_instance_valid(door): door.close()

	if respawn_point:
		_player.respawn_point = respawn_point
		_player.fainted.connect(_fail)
	started.emit()


func _spawn(point: Marker2D) -> void:
	var enemy := ENEMY_SCENE.instantiate() as EnemyNew
	enemy.player = _player
	enemy.shielded = shielded
	owner.add_child(enemy)
	enemy.global_position = point.global_position
	enemy.died.connect(_release.bind(enemy))
	_spawned.append(enemy)
	_pending.append(enemy)
	enemy.start_chase()


func _release(enemy: EnemyNew) -> void:
	_pending.erase(enemy)
	_spawned.erase(enemy)
	enemy.queue_free()
	if _pending.is_empty(): complete()


func _fail() -> void:
	_clear_respawn()
	for enemy in _spawned:
		if is_instance_valid(enemy): enemy.queue_free()
	_spawned.clear()
	_pending.clear()

	_player.set_physics_process(false)
	await _fade.fade_to(1.0, FAIL_FADE_IN).finished
	_player.global_position = respawn_point.global_position
	_player.revive()
	_open_doors()
	failed.emit()
	await get_tree().create_timer(FAIL_HOLD).timeout
	_player.set_physics_process(true)
	await _fade.fade_to(0.0, FAIL_FADE_OUT).finished
	_triggered = false
	set_deferred("monitoring", true)


func _open_doors() -> void:
	for door in doors:
		if is_instance_valid(door): door.open()


func _clear_respawn() -> void:
	if not is_instance_valid(_player): return
	if _player.respawn_point == respawn_point: _player.respawn_point = null
	if _player.fainted.is_connected(_fail): _player.fainted.disconnect(_fail)
