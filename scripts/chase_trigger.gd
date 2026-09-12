class_name ChaseTrigger
extends Area2D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is not Player: return
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is EnemyNew: enemy.start_chase()
	queue_free()
