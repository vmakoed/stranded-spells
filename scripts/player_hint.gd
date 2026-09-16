class_name PlayerHint
extends Node2D


const FADE_IN_DURATION = 0.15
const ICON_HOLD_DURATION = 1.0
const ICON_FADE_OUT_DURATION = 0.3
const TRANSITION_DELAY = 0.3
const TRANSITION_DURATION = 0.4
const TRANSITION_HOLD_DURATION = 0.6
const PROMPTS_HOLD_DURATION = 6.0
const PROMPTS_FADE_OUT_DURATION = 0.5
const RISE = 4.0
const ROW_SEPARATION = 2
const ICON_SIZE = Vector2(16, 16)


@export var label_settings: LabelSettings


var _tween: Tween
var _base_position: Vector2


@onready var icon_sprite: Sprite2D = %IconSprite
@onready var icon_overlay: Sprite2D = %IconOverlay
@onready var rows: VBoxContainer = %Rows


func _ready() -> void:
	_base_position = position
	rows.resized.connect(_center_rows)


func show_icon(texture: Texture2D) -> void:
	_reset()
	icon_sprite.texture = texture
	icon_sprite.modulate.a = 0.0
	icon_sprite.show()
	_tween = _begin(icon_sprite)
	_tween.tween_interval(ICON_HOLD_DURATION)
	_tween.tween_property(icon_sprite, "modulate:a", 0.0, ICON_FADE_OUT_DURATION)
	_tween.tween_callback(_reset)


func show_transition(from: Texture2D, to: Texture2D) -> void:
	_reset()
	icon_sprite.texture = from
	icon_overlay.texture = to
	icon_sprite.modulate.a = 0.0
	icon_overlay.modulate.a = 0.0
	icon_sprite.show()
	icon_overlay.show()
	_tween = _begin(icon_sprite)
	_tween.tween_interval(TRANSITION_DELAY)
	_tween.tween_property(icon_sprite, "modulate:a", 0.0, TRANSITION_DURATION)
	_tween.parallel().tween_property(icon_overlay, "modulate:a", 1.0, TRANSITION_DURATION)
	_tween.tween_interval(TRANSITION_HOLD_DURATION)
	_tween.tween_property(icon_overlay, "modulate:a", 0.0, ICON_FADE_OUT_DURATION)
	_tween.tween_callback(_reset)


func show_prompts(entries: Array[Dictionary]) -> void:
	if entries.is_empty(): return
	_reset()
	for entry in entries:
		rows.add_child(_make_row(entry))
	rows.modulate.a = 0.0
	rows.show()
	_tween = _begin(rows)
	_tween.tween_interval(PROMPTS_HOLD_DURATION)
	_tween.tween_property(rows, "modulate:a", 0.0, PROMPTS_FADE_OUT_DURATION)
	_tween.tween_callback(_reset)


func _begin(target: CanvasItem) -> Tween:
	position = _base_position + Vector2(0.0, RISE)
	var tween := create_tween()
	tween.tween_property(target, "modulate:a", 1.0, FADE_IN_DURATION)
	tween.parallel().tween_property(self, "position", _base_position, FADE_IN_DURATION)
	return tween


func _make_row(entry: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.use_parent_material = true
	row.add_theme_constant_override(&"separation", ROW_SEPARATION)

	var icon := TextureRect.new()
	icon.use_parent_material = true
	icon.texture = entry.get("icon")
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.custom_minimum_size = ICON_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	row.add_child(icon)

	var label := Label.new()
	label.use_parent_material = true
	label.text = entry["text"]
	label.label_settings = label_settings
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)
	return row


func _center_rows() -> void:
	rows.position = Vector2(-rows.size.x / 2.0, ICON_SIZE.y / 2.0 - rows.size.y)


func _reset() -> void:
	if _tween: _tween.kill()
	_tween = null
	icon_sprite.hide()
	icon_overlay.hide()
	for row in rows.get_children():
		rows.remove_child(row)
		row.queue_free()
	rows.hide()
	position = _base_position
