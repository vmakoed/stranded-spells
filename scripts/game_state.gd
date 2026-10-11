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
@export var spell_unlocks : Dictionary[SpellDefinitions.Spell, bool]
@export var room_flags : Dictionary = {}
@export var inventory : Array[String] = []

static var _flag_writers := {}

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

static func get_spell_unlocks() -> Dictionary[SpellDefinitions.Spell, bool]:
	if not has_game_state(): 
		return SpellSystem.DEFAULT_UNLOCKS
	var game_state := get_or_create_state()
	return game_state.spell_unlocks

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

static func set_spell_unlocks(value: Dictionary[SpellDefinitions.Spell, bool]) -> void:
	var game_state := get_or_create_state()
	game_state.spell_unlocks = value
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

static func level_path_to_room_number(level_path: String) -> String:
	return level_path \
		.get_file() \
		.trim_suffix(".tscn") \
		.trim_prefix("room_")

static func get_inventory() -> Array[String]:
	if not has_game_state():
		return []
	return get_or_create_state().inventory

static func add_item(item_name : String) -> void:
	var game_state := get_or_create_state()
	if item_name in game_state.inventory: return
	game_state.inventory.append(item_name)
	GlobalState.save()

static func get_flag(node : Node, default : Variant = null) -> Variant:
	var id : String = node.save_id
	if id.is_empty() or not has_game_state():
		return default
	return _room_flags(node).get(id, default)

static func set_flag(node : Node, value : Variant) -> void:
	var id : String = node.save_id
	if id.is_empty(): return
	var room := _room_flags(node)
	_warn_duplicate(node, room, id)
	room[id] = value
	GlobalState.save()

static func _room_flags(node : Node) -> Dictionary:
	var root := node
	while root.owner:
		root = root.owner
	var path := root.scene_file_path
	var uid := ResourceLoader.get_resource_uid(path)
	var key := ResourceUID.id_to_text(uid) if uid != ResourceUID.INVALID_ID else path
	var game_state := get_or_create_state()
	if not game_state.room_flags.has(key):
		game_state.room_flags[key] = {}
	var room : Dictionary = game_state.room_flags[key]
	room["_room"] = path.get_file().get_basename()
	return room

static func _warn_duplicate(node : Node, room : Dictionary, id : String) -> void:
	if not OS.is_debug_build(): return
	var writer_key := "%s/%s" % [room["_room"], id]
	var node_path := str(node.get_path())
	var previous : String = _flag_writers.get(writer_key, node_path)
	if previous != node_path:
		push_warning("Duplicate save_id '%s' in %s: %s and %s" % [id, room["_room"], previous, node_path])
	_flag_writers[writer_key] = node_path

static func unlock_spell(spell: SpellDefinitions.Spell) -> void:
	set_spell_unlocks(
		get_spell_unlocks() \
			.merged({spell: true}, true)
	)


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
	game_state.spell_unlocks = SpellSystem.DEFAULT_UNLOCKS
	game_state.room_flags = {}
	game_state.inventory = []
	GlobalState.save()
