extends Node


signal level_won(level_path: String)


const EXIT_UP_PATH = "res://scenes/game_scene/levels/room_1.tscn"


@onready var door_up: Door = %DoorUp
@onready var player_spawn_up_marker: Marker2D = %PlayerSpawnUpMarker
@onready var player_character: Player = %PlayerCharacter

@onready var boxes: Node = %Boxes


var level_state: LevelState
var boxes_count: int


func _ready() -> void:
	_position_player()

	level_state = GameState.get_level_state(scene_file_path)
	if level_state.cleared:
		_ready_cleared_level()
	else:
		_ready_active_level()


func _position_player() -> void:
	if GameState.get_checkpoint_level_entry_direction() == GameState.EntryDirection.UP:
		player_character.global_position = player_spawn_up_marker.global_position


func _ready_cleared_level() -> void:
	_open_doors()
	for box: Box in boxes.get_children():
		box.queue_free()


func _ready_active_level() -> void:
	boxes_count = boxes.get_child_count()

	for box: Box in boxes.get_children():
		box.destroyed.connect(_on_box_destroyed)


func _open_doors() -> void:
	door_up.open()


func _clear_level() -> void:
	_open_doors()
	player_character.save_health()
	level_state.cleared = true
	GlobalState.save()


func _on_box_destroyed() -> void:
	boxes_count -= 1
	if boxes_count == 0: _clear_level()


func _on_exit_up_area_body_entered(body: Node2D) -> void:
	if body is Player: 
		GameState.set_checkpoint_level_entry_direction(GameState.EntryDirection.DOWN)
		level_won.emit(EXIT_UP_PATH)
