class_name Challenge
extends Area2D


signal started
signal completed


@export var enemies: Array[EnemyNew] = []
@export var doors: Array[ChallengeDoor] = []


var _pending: Array[EnemyNew] = []
var _triggered := false
var _completed := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_on_body_entered)


func complete() -> void:
	if _completed: return
	_completed = true
	for door in doors:
		if is_instance_valid(door): door.open()
	completed.emit()
	queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body is not Player or _triggered: return
	_triggered = true
	set_deferred("monitoring", false)

	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion(): continue
		_pending.append(enemy)
		enemy.died.connect(_release.bind(enemy))
		enemy.start_chase()

	if not enemies.is_empty() and _pending.is_empty():
		queue_free()
		return

	for door in doors:
		if is_instance_valid(door): door.close()
	started.emit()


func _release(enemy: EnemyNew) -> void:
	_pending.erase(enemy)
	if _pending.is_empty(): complete()
