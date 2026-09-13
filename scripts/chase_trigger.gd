class_name ChaseTrigger
extends Area2D


@export var enemies: Array[EnemyNew] = []


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is not Player: return
	for enemy in enemies:
		if is_instance_valid(enemy): enemy.start_chase()
	queue_free()
