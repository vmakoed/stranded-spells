extends Room


@onready var enemy_target: Enemy = %EnemyTarget
@onready var enemy_marker: Marker2D = %EnemyMarker


func _respawn_enemy() -> void:
	var enemy_scene : PackedScene = load("res://scenes/enemy.tscn")
	var enemy_instance : Enemy = enemy_scene.instantiate()
	enemy_instance.global_position = enemy_marker.global_position
	enemy_instance.player = player_character
	_setup_enemy_signals(enemy_instance)
	enemies_node.add_child(enemy_instance)


func _on_enemy_destroyed() -> void:
	if enemy_target and (not enemy_target.dead):
		_respawn_enemy()
	else:
		enemies_count = 0
		for enemy: Enemy in _get_enemies(): enemy.queue_free()
		_clear_level()
