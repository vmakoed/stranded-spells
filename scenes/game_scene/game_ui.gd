extends Control


const PROMPT_HIGHLIGHT_COLOR = Color(0.5, 0.72, 0.78, 1.0)
const INITIAL_PROMPT_MODULATE = Color(1, 1, 1, 1)
const PROMPT_MODULATE_DURATION = 2.0


var tween: Tween


@onready var health_progress_bar: ProgressBar = %HealthProgressBar
@onready var spell_prompt_containers: Dictionary[SpellDefinitions.Spell, HBoxContainer] = {
	SpellDefinitions.Spell.PUSH: %PushPromptsContainer,
	SpellDefinitions.Spell.FROST: %FrostPromptsContainer,
	SpellDefinitions.Spell.SHOCK: %ShockPromptsContainer,
	SpellDefinitions.Spell.FIRE: %FirePromptsContainer
}


func _ready() -> void:
	GameUIBridge.health_changed.connect(_on_health_changed)
	SpellSystem.spell_in_progress.connect(_on_spell_in_progress)
	SpellSystem.spell_casted.connect(_on_spell_casted)


func _reset_prompts() -> void:
	for prompt_container in spell_prompt_containers.values():
		for prompt in prompt_container.get_children():
			prompt.modulate = INITIAL_PROMPT_MODULATE


func _active_prompt_textures(spell: SpellDefinitions.Spell, sequence_size: int) -> Array[Node]:
	return _prompt_textures(spell).slice(0, sequence_size)


func _prompt_textures(spell: SpellDefinitions.Spell) -> Array[Node]:
	return spell_prompt_containers[spell].get_children()


func _on_health_changed(value: float, max_value: float) -> void:
	health_progress_bar.max_value = max_value
	health_progress_bar.value = value


func _on_spell_in_progress(spell: SpellDefinitions.Spell, sequence_size: int) -> void:
	_reset_prompts()
	for prompt: TextureRect in _active_prompt_textures(spell, sequence_size):
		prompt.modulate = PROMPT_HIGHLIGHT_COLOR


func _on_spell_casted(spell: SpellDefinitions.Spell) -> void:
	_reset_prompts()
	tween = create_tween()
	for prompt: TextureRect in _prompt_textures(spell):
		prompt.modulate = PROMPT_HIGHLIGHT_COLOR
		tween \
			.parallel() \
			.tween_property(
				prompt,
				"modulate",
				INITIAL_PROMPT_MODULATE,
				PROMPT_MODULATE_DURATION
			).from(PROMPT_HIGHLIGHT_COLOR)
