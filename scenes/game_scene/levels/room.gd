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


func _ready() -> void:
	GameUIBridge.room_changed.emit()
	_initialize_doors()
	_initialize_markers()
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


func _ready_level() -> void:
	if level_state.cleared:
		_ready_cleared_level()
	else:
		_ready_active_level()


func _ready_cleared_level() -> void:
	_open_doors()


func _ready_active_level() -> void:
	player_character.destroyed.connect(func(): level_lost.emit())


func _clear_level() -> void:
	_open_doors()
	player_character.save_health()
	level_state.cleared = true
	GlobalState.save()


func _open_doors() -> void:
	if door_up: door_up.open() 
	if door_right: door_right.open()
	if door_down: door_down.open()
	if door_left: door_left.open()


func _close_doors() -> void:
	if door_up: door_up.close() 
	if door_right: door_right.close()
	if door_down: door_down.close()
	if door_left: door_left.oclosepen()


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
