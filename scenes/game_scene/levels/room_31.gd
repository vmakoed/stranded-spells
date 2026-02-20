extends Room


@onready var enemy_trigger_area: Area2D = %EnemyTriggerArea
@onready var enemies: Node = %Enemies


var enemies_count: int
var combat_started := false


func _ready_cleared_level() -> void:
	super()

	for enemy: Enemy in enemies.get_children():
		enemy.queue_free()


func _ready_active_level() -> void:
	super()
	enemies_count = enemies.get_child_count()

	for enemy: Enemy in enemies.get_children():
		enemy.destroyed.connect(_on_enemy_destroyed)


func _on_enemy_destroyed() -> void:
	enemies_count -= 1
	if enemies_count == 0: _clear_level()


func _on_enemy_trigger_area_body_entered(body: Node2D) -> void:
	if enemies_count > 0 and body is Player and !combat_started:
		_close_doors()
		_start_combat()


func _start_combat() -> void:
	combat_started = true
	for enemy: Enemy in enemies.get_children():
		enemy.player = player_character
