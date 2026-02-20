class_name GameState
extends Resource

enum EntryDirection {UP, DOWN, LEFT, RIGHT, NONE}

const STATE_NAME : String = "GameState"
const FILE_PATH = "res://scripts/game_state.gd"

@export var level_states : Dictionary = {}
@export var current_level_path : String
@export var checkpoint_level_path : String
@export var total_games_played : int
@export var play_time : int
@export var total_time : int

@export var player_character_health : float = Player.MAX_HEALTH
@export var checkpoint_level_entry_direction : EntryDirection = EntryDirection.NONE

static func get_level_state(level_state_key : String) -> LevelState:
	if not has_game_state(): 
		return
	var game_state := get_or_create_state()
	if level_state_key.is_empty() : return
	if level_state_key in game_state.level_states:
		return game_state.level_states[level_state_key] 
	else:
		var new_level_state := LevelState.new()
		game_state.level_states[level_state_key] = new_level_state
		GlobalState.save()
		return new_level_state

static func get_level_state_keys() -> Array:
	if not has_game_state(): 
		return []
	var game_state := get_or_create_state()
	return game_state.level_states.keys()

static func has_game_state() -> bool:
	return GlobalState.has_state(STATE_NAME)

static func get_or_create_state() -> GameState:
	return GlobalState.get_or_create_state(STATE_NAME, FILE_PATH)

static func get_current_level_path() -> String:
	if not has_game_state(): 
		return ""
	var game_state := get_or_create_state()
	return game_state.current_level_path

static func get_checkpoint_level_path() -> String:
	if not has_game_state(): 
		return ""
	var game_state := get_or_create_state()
	return game_state.checkpoint_level_path

static func get_levels_reached() -> int:
	if not has_game_state(): 
		return 0
	var game_state := get_or_create_state()
	return game_state.level_states.size()

static func get_checkpoint_level_entry_direction() -> EntryDirection:
	if not has_game_state(): 
		return EntryDirection.NONE
	var game_state := get_or_create_state()
	return game_state.checkpoint_level_entry_direction

static func get_player_character_health() -> float:
	if not has_game_state(): 
		return Player.MAX_HEALTH
	var game_state := get_or_create_state()
	return game_state.player_character_health

static func set_checkpoint_level_path(level_path : String) -> void:
	var game_state := get_or_create_state()
	game_state.checkpoint_level_path = level_path
	get_level_state(level_path)
	GlobalState.save()

static func set_current_level_path(level_path : String) -> void:
	var game_state := get_or_create_state()
	game_state.current_level_path = level_path
	GlobalState.save()

static func set_checkpoint_level_entry_direction(entry_direction: EntryDirection) -> void:
	var game_state := get_or_create_state()
	game_state.checkpoint_level_entry_direction = entry_direction
	GlobalState.save()

static func set_player_character_health(value: float) -> void:
	var game_state := get_or_create_state()
	game_state.player_character_health = value
	GlobalState.save()

static func get_current_room() -> String:
	return level_path_to_room_number(
		ResourceUID.ensure_path(get_current_level_path())
	)

static func get_visited_rooms() -> Array:
	return get_level_state_keys() \
		.map(
			func(key: String): return level_path_to_room_number(
				ResourceUID.ensure_path(key)
			)
		)

static func level_path_to_room_number(level_path: String)-> String:
	return level_path \
		.get_file() \
		.trim_suffix(".tscn") \
		.trim_prefix("room_")

static func start_game() -> void:
	var game_state := get_or_create_state()
	game_state.total_games_played += 1
	GlobalState.save()

static func continue_game() -> void:
	var game_state := get_or_create_state()
	game_state.current_level_path = game_state.checkpoint_level_path
	GlobalState.save()

static func reset() -> void:
	var game_state := get_or_create_state()
	game_state.level_states = {}
	game_state.current_level_path = ""
	game_state.checkpoint_level_path = ""
	game_state.play_time = 0
	game_state.total_time = 0
	game_state.player_character_health = Player.MAX_HEALTH
	game_state.checkpoint_level_entry_direction = EntryDirection.NONE
	GlobalState.save()
