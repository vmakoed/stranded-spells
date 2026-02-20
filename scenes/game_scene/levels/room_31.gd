extends Node


signal level_won(level_path: String)
signal level_lost


@export_file("*.tscn") var exit_down_path: String


@onready var door_up: Door = %DoorUp
@onready var door_down: Door = %DoorDown

@onready var player_spawn_down_marker: Marker2D = %PlayerSpawnDownMarker
@onready var player_character: Player = %PlayerCharacter

@onready var enemy_trigger_area: Area2D = %EnemyTriggerArea
@onready var enemies: Node = %Enemies


var level_state: LevelState
var enemies_count: int
var combat_started := false


func _ready() -> void:
	_position_player()

	level_state = GameState.get_level_state(scene_file_path)
	if level_state.cleared:
		_ready_cleared_level()
	else:
		_ready_active_level()


func _position_player() -> void:
	if GameState.get_checkpoint_level_entry_direction() == GameState.EntryDirection.DOWN:
		player_character.global_position = player_spawn_down_marker.global_position


func _ready_cleared_level() -> void:
	_open_doors()

	for enemy: Enemy in enemies.get_children():
		enemy.queue_free()


func _ready_active_level() -> void:
	door_down.open() 
	player_character.destroyed.connect(func(): level_lost.emit())
	enemies_count = enemies.get_child_count()

	for enemy: Enemy in enemies.get_children():
		enemy.destroyed.connect(_on_enemy_destroyed)


func _clear_level() -> void:
	_open_doors()
	player_character.save_health()
	level_state.cleared = true
	GlobalState.save()


func _open_doors() -> void:
	door_up.open()
	door_down.open()


func _on_enemy_destroyed() -> void:
	enemies_count -= 1
	if enemies_count == 0: _clear_level()


func _on_enemy_trigger_area_body_entered(body: Node2D) -> void:
	if enemies_count > 0 and body is Player and !combat_started:
		door_down.close()
		_follow_player(body)


func _follow_player(player: Player) -> void:
	combat_started = true
	for enemy: Enemy in enemies.get_children():
		enemy.player = player


func _on_exit_up_area_body_entered(body: Node2D) -> void:
	if body is Player:
		level_won.emit()


func _on_exit_down_area_body_entered(body: Node2D) -> void:
	if (body is Player) and exit_down_path:
		GameState.set_checkpoint_level_entry_direction(GameState.EntryDirection.UP)
		level_won.emit(exit_down_path)
