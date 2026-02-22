class_name Room
extends Node


signal level_won(level_path: String)
signal level_lost


@export_file("*.tscn") var exit_up_path: String
@export_file("*.tscn") var exit_left_path: String
@export_file("*.tscn") var exit_down_path: String
@export_file("*.tscn") var exit_right_path: String

@onready var player_character: Player = %PlayerCharacter


var level_state: LevelState

var player_spawn_up_marker: Marker2D
var player_spawn_right_marker: Marker2D
var player_spawn_down_marker: Marker2D
var player_spawn_left_marker: Marker2D

var door_up: Door
var door_down: Door
var door_left: Door
var door_right: Door

var enemies_node: Node
var enemies_count := 0
var challenge_started := false


func _ready() -> void:
	GameUIBridge.room_changed.emit()
	_initialize_doors()
	_initialize_markers()
	_initialize_enemies()
	level_state = GameState.get_level_state(scene_file_path)
	_ready_level()
	_position_player()


func _position_player() -> void:
	if (GameState.get_checkpoint_level_entry_direction() == GameState.EntryDirection.NONE):
		return

	if player_spawn_up_marker and (GameState.get_checkpoint_level_entry_direction() == GameState.EntryDirection.UP):
		player_character.global_position = player_spawn_up_marker.global_position
		door_up.open()

	if player_spawn_right_marker and (GameState.get_checkpoint_level_entry_direction() == GameState.EntryDirection.RIGHT):
		player_character.global_position = player_spawn_right_marker.global_position
		door_right.open()

	if player_spawn_down_marker and (GameState.get_checkpoint_level_entry_direction() == GameState.EntryDirection.DOWN):
		player_character.global_position = player_spawn_down_marker.global_position
		door_down.open()

	if player_spawn_left_marker and (GameState.get_checkpoint_level_entry_direction() == GameState.EntryDirection.LEFT):
		player_character.global_position = player_spawn_left_marker.global_position
		door_left.open()


func _initialize_doors() -> void:
	door_up = get_node_or_null("%DoorUp")
	door_down = get_node_or_null("%DoorDown")
	door_left = get_node_or_null("%DoorLeft")
	door_right = get_node_or_null("%DoorRight")


func _initialize_markers() -> void:
	player_spawn_up_marker = get_node_or_null("%PlayerSpawnUpMarker")
	player_spawn_right_marker = get_node_or_null("%PlayerSpawnRightMarker")
	player_spawn_down_marker = get_node_or_null("%PlayerSpawnDownMarker")
	player_spawn_left_marker = get_node_or_null("%PlayerSpawnLeftMarker")


func _initialize_enemies() -> void:
	enemies_node = get_node_or_null("%Enemies")


func _ready_level() -> void:
	if level_state.cleared:
		_ready_cleared_level()
	else:
		_ready_active_level()


func _ready_cleared_level() -> void:
	_open_doors()
	for enemy: Enemy in _get_enemies(): enemy.queue_free()


func _ready_active_level() -> void:
	player_character.destroyed.connect(func(): level_lost.emit())

	if enemies_node:
		enemies_count = enemies_node.get_child_count()
		for enemy: Enemy in _get_enemies(): _setup_enemy_signals(enemy)
	else:
		enemies_count = 0


func _clear_level() -> void:
	_open_doors(true)
	player_character.save_health()
	level_state.cleared = true
	GlobalState.save()


func _open_doors(with_sound = false) -> void:
	if door_up: door_up.open(with_sound) 
	if door_right: door_right.open(with_sound)
	if door_down: door_down.open(with_sound)
	if door_left: door_left.open(with_sound)


func _close_doors(with_sound = false) -> void:
	if door_up: door_up.close(with_sound) 
	if door_right: door_right.close(with_sound)
	if door_down: door_down.close(with_sound)
	if door_left: door_left.close(with_sound)


func _start_challenge() -> void:
	for enemy: Enemy in _get_enemies(): 
		enemy.player = player_character
	challenge_started = true
	_close_doors(true)


func _get_enemies() -> Array[Node]:
	if enemies_node: 
		return enemies_node.get_children()
	else:
		return []


func _setup_enemy_signals(enemy: Enemy) -> void:
	enemy.destroyed.connect(_on_enemy_destroyed)


func _on_enemy_destroyed() -> void:
	enemies_count -= 1
	if enemies_count == 0: _clear_level()


func _on_exit_up_area_body_entered(body: Node2D) -> void:
	if (body is Player) and exit_up_path:
		GameState.set_checkpoint_level_entry_direction(GameState.EntryDirection.DOWN)
		level_won.emit(exit_up_path)


func _on_exit_right_area_body_entered(body: Node2D) -> void:
	if (body is Player) and exit_right_path:
		GameState.set_checkpoint_level_entry_direction(GameState.EntryDirection.LEFT)
		level_won.emit(exit_right_path)


func _on_exit_down_area_body_entered(body: Node2D) -> void:
	if (body is Player) and exit_down_path:
		GameState.set_checkpoint_level_entry_direction(GameState.EntryDirection.UP)
		level_won.emit(exit_down_path)


func _on_exit_left_area_body_entered(body: Node2D) -> void:
	if (body is Player) and exit_left_path:
		GameState.set_checkpoint_level_entry_direction(GameState.EntryDirection.RIGHT)
		level_won.emit(exit_left_path)


func _on_start_challege_area_body_entered(body: Node2D) -> void:
	if level_state.cleared == true: return
	if challenge_started: return
	if not body is Player: return

	_start_challenge()
