@tool
extends PanelContainer


const PROMPT_HIGHLIGHT_COLOR = Color(0.5, 0.72, 0.78, 1.0)
const PROMPT_MODULATE_DURATION = 2.0


@export var prompt_name: String
@export var prompt_textures: Array[AtlasTexture]


var tween: Tween


@onready var prompt_container: BoxContainer = %PromptsContainer


func _ready() -> void:
	%Label.text = prompt_name
	for texture in prompt_textures:
		var texture_rect = TextureRect.new()
		texture_rect.texture = texture
		texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH
		prompt_container.add_child(texture_rect)


func highlight(sequence_size: int) -> void:
	for prompt: TextureRect in _prompt_textures().slice(0, sequence_size):
		prompt.modulate = PROMPT_HIGHLIGHT_COLOR


func fadeout_highlight() -> void:
	tween = create_tween()

	for prompt: TextureRect in _prompt_textures():
		prompt.modulate = PROMPT_HIGHLIGHT_COLOR
		tween \
			.parallel() \
			.tween_property(
				prompt,
				"modulate",
				Color.WHITE,
				PROMPT_MODULATE_DURATION
			).from(PROMPT_HIGHLIGHT_COLOR)


func reset_highlight() -> void:
	if tween: tween.stop()
	for prompt in prompt_container.get_children():
		prompt.modulate = Color.WHITE


func _prompt_textures() -> Array[Node]:
	return prompt_container.get_children()
