@tool
class_name CastGuide
extends Node2D


const GLYPH_SIZE = 16
const GLYPHS: Dictionary[String, Texture2D] = {
	"LT": preload("res://resources/prompt_lt.tres"),
	"RT": preload("res://resources/prompt_rt.tres"),
	"RS": preload("res://resources/prompt_rs.tres"),
	"RB": preload("res://resources/prompt_rb.tres"),
	"ABXY": preload("res://assets/textures/prompt_abxy.png"),
	"FACE_BOTTOM": preload("res://resources/prompt_face_bottom.tres"),
	"FACE_RIGHT": preload("res://resources/prompt_face_right.tres"),
	"FACE_LEFT": preload("res://resources/prompt_face_left.tres"),
	"FACE_TOP": preload("res://resources/prompt_face_top.tres"),
}


@export var player: Player
@export_multiline var prepare_text := "Hold {LT}: prepare spell":
	set(value):
		prepare_text = value
		if is_node_ready(): _refresh()
@export_multiline var equipped_text := "{RS}: aim {RT}: cast {RB}: unequip"
@export_multiline var draw_text := "{FACE_BOTTOM} {FACE_TOP}: draw glyph"
@export_multiline var release_text := "Release {LT}"


var _has_wand := false
var _casting := false
var _equipped := false
var _shown_text := ""
var _token_regex := RegEx.create_from_string("\\{(\\w+)\\}")


@onready var label: RichTextLabel = %Text


func _ready() -> void:
	label.minimum_size_changed.connect(_center_label)
	if Engine.is_editor_hint():
		_refresh()
		return
	_has_wand = is_instance_valid(player) and player.has_item(Player.Item.WAND)
	GameUIBridge.inventory_changed.connect(_on_inventory_changed)
	GameUIBridge.cast_mode_changed.connect(_on_cast_mode_changed)
	GameUIBridge.spell_equipped.connect(_on_spell_equipped)
	GameUIBridge.spell_reset.connect(_on_spell_reset)
	_refresh()


func _on_inventory_changed(items: Array[Player.Item]) -> void:
	_has_wand = Player.Item.WAND in items
	_refresh()


func _on_cast_mode_changed(active: bool) -> void:
	_casting = active
	_refresh()


func _on_spell_equipped(_spell: CastInputPanel.Spell) -> void:
	_equipped = true
	_refresh()


func _on_spell_reset() -> void:
	_equipped = false
	_refresh()


func _refresh() -> void:
	visible = _has_wand or Engine.is_editor_hint()
	var text: String
	if _casting:
		text = release_text if _equipped else draw_text
	else:
		text = equipped_text if _equipped else prepare_text
	if text == _shown_text: return
	_shown_text = text
	_build(text)


func _build(template: String) -> void:
	label.clear()
	label.push_paragraph(HORIZONTAL_ALIGNMENT_CENTER)
	var cursor := 0
	for found in _token_regex.search_all(template):
		label.add_text(template.substr(cursor, found.get_start() - cursor))
		var token := found.get_string(1)
		if GLYPHS.has(token):
			label.add_image(GLYPHS[token], GLYPH_SIZE, GLYPH_SIZE, Color.WHITE, INLINE_ALIGNMENT_CENTER)
		else:
			label.add_text(found.get_string())
		cursor = found.get_end()
	label.add_text(template.substr(cursor))
	label.pop()


func _center_label() -> void:
	label.reset_size()
	label.position = (-label.size / 2.0).round()
