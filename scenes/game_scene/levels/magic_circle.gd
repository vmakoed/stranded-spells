class_name MagicCircle
extends Node2D


const ACTIVE_TINT = Color(0.5, 0.72, 0.78, 1.0)
const INACTIVE_TINT = Color(1.0, 1.0, 1.0, 0.35)
const ANCHOR_COLOR = Color(1.0, 1.0, 1.0, 0.25)
const ANCHOR_RADIUS = 1.0
const ACTIVE_RADIUS = 1.5
const LINE_WIDTH = 1.0
const GROUP_NAME = &"magic_circle"


var sequence: Array[StringName] = []


@onready var ring_sprite: Sprite2D = %CircleRing
@onready var marker_sprites: Dictionary[StringName, Sprite2D] = {
	CastInputPanel.SPELL_ACTIONS[CastInputPanel.SpellDirection.UP]: %CircleMarkerUp,
	CastInputPanel.SPELL_ACTIONS[CastInputPanel.SpellDirection.RIGHT]: %CircleMarkerRight,
	CastInputPanel.SPELL_ACTIONS[CastInputPanel.SpellDirection.DOWN]: %CircleMarkerDown,
	CastInputPanel.SPELL_ACTIONS[CastInputPanel.SpellDirection.LEFT]: %CircleMarkerLeft
}


func _ready() -> void:
	add_to_group(GROUP_NAME)
	hide()	# shown only while cast mode is held, see GameUIBridge.cast_mode_changed
	_update_tints()


func get_marker_canvas_position(action: StringName) -> Vector2:
	return marker_sprites[action].get_global_transform_with_canvas().origin


func set_sequence(new_sequence: Array[StringName]) -> void:
	sequence = new_sequence.duplicate()	# emitted array is a live reference to CastInputPanel.spell_sequence
	_update_tints()
	queue_redraw()


func clear_sequence() -> void:
	sequence.clear()
	_update_tints()
	queue_redraw()


func _update_tints() -> void:
	for action in marker_sprites:
		var tint := ACTIVE_TINT if action in sequence else INACTIVE_TINT
		marker_sprites[action].material.set_shader_parameter(&"tint", tint)

	# Ring matches inactive markers while casting, active once a spell is ready.
	var spell_ready := CastInputPanel.find_complete_spell(sequence) != null
	ring_sprite.material.set_shader_parameter(&"tint", ACTIVE_TINT if spell_ready else INACTIVE_TINT)


func _draw() -> void:
	for action in marker_sprites:
		var is_active := action in sequence
		draw_circle(
			marker_sprites[action].position,
			ACTIVE_RADIUS if is_active else ANCHOR_RADIUS,
			ACTIVE_TINT if is_active else ANCHOR_COLOR
		)

	for index in sequence.size() - 1:
		draw_line(
			marker_sprites[sequence[index]].position,
			marker_sprites[sequence[index + 1]].position,
			ACTIVE_TINT,
			LINE_WIDTH
		)
