extends Node


signal level_won(level_path : String)
signal level_lost


@onready var door_up: Door = %DoorUp
@onready var door_down: Door = %DoorDown
@onready var enemy_trigger_area: Area2D = %EnemyTriggerArea
@onready var enemies: Node = %Enemies
@onready var player_character: Player = %PlayerCharacter


var enemies_count: int
var combat_started := false


func _ready() -> void:
	door_down.open() 
	player_character.destroyed.connect(func(): level_lost.emit())
	enemies_count = enemies.get_child_count()

	for enemy: Enemy in enemies.get_children():
		enemy.destroyed.connect(_on_enemy_destroyed)


func _on_enemy_destroyed() -> void:
	enemies_count -= 1

	if enemies_count == 0:
		door_up.open()
		door_down.open()


func _on_win_area_body_entered(body: Node2D) -> void:
	if body is Player:
		level_won.emit()


func _on_enemy_trigger_area_body_entered(body: Node2D) -> void:
	if enemies_count > 0 and body is Player and !combat_started:
		door_down.close()
		_follow_player(body)


func _follow_player(player: Player) -> void:
	combat_started = true
	for enemy: Enemy in enemies.get_children():
		enemy.player = player
