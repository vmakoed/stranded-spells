extends Control


const PROMPT_HIGHLIGHT_COLOR = Color(0.5, 0.72, 0.78, 1.0)
const INITIAL_PROMPT_MODULATE = Color(1, 1, 1, 1)
const PROMPT_MODULATE_DURATION = 2.0
const PROMPT_TEXTURE_MAP: Dictionary[SpellDefinitions.SpellDirection, AtlasTexture] = {
	SpellDefinitions.SpellDirection.UP: preload("res://resources/input_up_texture.tres"),
	SpellDefinitions.SpellDirection.DOWN: preload("res://resources/input_down_texture.tres"),
	SpellDefinitions.SpellDirection.LEFT: preload("res://resources/input_left_texture.tres"),
	SpellDefinitions.SpellDirection.RIGHT: preload("res://resources/input_right_texture.tres")
}


var player_heart_scene = preload("res://scenes/player_heart.tscn")


@onready var health_progress_bar: ProgressBar = %HealthProgressBar
@onready var player_hearts_container: HBoxContainer = %PlayerHeartsContainer
@onready var mini_map: MiniMap = %MiniMap
@onready var level_title_container = %LevelTitleContainer
@onready var level_title_label = %LevelTitleLabel

# TODO: dynamically generate prompts
@onready var spell_prompt_containers: Dictionary[SpellDefinitions.Spell, PanelContainer] = {
	SpellDefinitions.Spell.PUSH: %PushContainer,
	SpellDefinitions.Spell.FROST: %FrostContainer,
	SpellDefinitions.Spell.SHOCK: %ShockContainer,
	SpellDefinitions.Spell.FIRE: %FireContainer
}

# @onready var spell_prompt_containers: Dictionary[SpellDefinitions.Spell, HBoxContainer] = {
# 	SpellDefinitions.Spell.PUSH: %PushPromptsContainer,
# 	SpellDefinitions.Spell.FROST: %FrostPromptsContainer,
# 	SpellDefinitions.Spell.SHOCK: %ShockPromptsContainer,
# 	SpellDefinitions.Spell.FIRE: %FirePromptsContainer
# }


func _ready() -> void:
	GameUIBridge.health_changed.connect(_on_health_changed)
	GameUIBridge.room_changed.connect(_on_room_changed)
	GameUIBridge.spell_unlocked.connect(_on_spell_unlocked)
	SpellSystem.spell_in_progress.connect(_on_spell_in_progress)
	SpellSystem.spell_casted.connect(_on_spell_casted)
	SpellSystem.spell_sequence_cleared.connect(_on_spell_sequence_cleared)

	_refresh_spell_prompts()


func _refresh_spell_prompts() -> void:
	var spell_unlocks = GameState.get_spell_unlocks()
	for spell: SpellDefinitions.Spell in spell_unlocks:
		spell_prompt_containers[spell].visible = spell_unlocks[spell]


func _reset_prompt_highlights() -> void:
	for prompt_container in spell_prompt_containers.values():
		prompt_container.reset_highlight()


func _on_room_changed() -> void:
	pass
	# mini_map.refresh()
	# _refresh_level_title()


func _refresh_level_title() -> void:
	var room_title = MapConfiguration.ROOM_TITLES.get(GameState.get_current_room())
	if room_title:
		level_title_container.visible = true
		level_title_label.text = room_title
	else:
		level_title_container.visible = false
		level_title_label.text = ""


func _on_health_changed(value: float, max_value: float) -> void:
	health_progress_bar.max_value = max_value
	health_progress_bar.value = value
	_refresh_player_hearts(value, max_value)


func _refresh_player_hearts(value: float, max_value: float) -> void:
	var hearts_total := maxi(int(ceil(max_value)), 0)
	var hearts_solid := clampi(int(ceil(value)), 0, hearts_total)

	var hearts := player_hearts_container.get_children()
	while hearts.size() > hearts_total:
		var heart = hearts.pop_back()
		player_hearts_container.remove_child(heart)
		heart.queue_free()
	while hearts.size() < hearts_total:
		var heart = player_heart_scene.instantiate()
		player_hearts_container.add_child(heart)
		hearts.append(heart)

	for i in hearts.size():
		hearts[i].solid = i < hearts_solid


func _on_spell_unlocked() -> void:
	_refresh_spell_prompts()


func _on_spell_in_progress(spell: SpellDefinitions.Spell, sequence_size: int) -> void:
	_reset_prompt_highlights()
	spell_prompt_containers[spell].highlight(sequence_size)


func _on_spell_casted(spell: SpellDefinitions.Spell) -> void:
	spell_prompt_containers[spell].fadeout_highlight()


func _on_spell_sequence_cleared() -> void:
	_reset_prompt_highlights()
