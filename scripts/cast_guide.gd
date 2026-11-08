@tool
class_name CastGuide
extends Node2D


const GLYPH_SIZE = 16
const GLYPHS: Dictionary[String, Texture2D] = {
	"LT": preload("res://resources/prompt_lt.tres"),
	"RT": preload("res://resources/prompt_rt.tres"),
	"RS": preload("res://resources/prompt_rs.tres"),
	"RB": preload("res://resources/prompt_rb.tres"),
	"LB": preload("res://resources/prompt_lb.tres"),
	"ABXY": preload("res://assets/textures/prompt_abxy.png"),
	"FACE_BOTTOM": preload("res://resources/prompt_face_bottom.tres"),
	"FACE_RIGHT": preload("res://resources/prompt_face_right.tres"),
	"FACE_LEFT": preload("res://resources/prompt_face_left.tres"),
	"FACE_TOP": preload("res://resources/prompt_face_top.tres"),
}


@export_multiline var prepare_text := "Hold {LT} {LB}: prepare spell":
	set(value):
		prepare_text = value
		if is_node_ready(): _refresh()
@export_multiline var equipped_text := "{RS}: aim {RT} {RB}: cast"
@export_multiline var prepare_text_single := "Hold {LT}: prepare spell"
@export_multiline var equipped_text_single := "{RS}: aim {RT}: cast"
@export_multiline var draw_text := "{FACE_BOTTOM} {FACE_TOP}: draw glyph"
@export_multiline var release_text := "Release {HOLD}"
@export var min_known_spells := 1


var _casting := false
var _equipped_slots: Array[bool] = [false, false]
var _active_slot := 0
var _sequence_complete := false
var _shown_text := ""
var _token_regex := RegEx.create_from_string("\\{(\\w+)\\}")


@onready var label: RichTextLabel = %Text


func _ready() -> void:
	label.minimum_size_changed.connect(_center_label)
	if Engine.is_editor_hint():
		_refresh()
		return
	GameUIBridge.spells_changed.connect(_on_spells_changed)
	GameUIBridge.cast_mode_changed.connect(_on_cast_mode_changed)
	GameUIBridge.spell_equipped.connect(_on_spell_equipped)
	GameUIBridge.spell_reset.connect(_on_spell_reset)
	GameUIBridge.spell_sequence_changed.connect(_on_spell_sequence_changed)
	_refresh()


func _on_spells_changed(_spells: Array[CastInputPanel.Spell]) -> void:
	_refresh()


func _on_cast_mode_changed(active: bool, slot: int) -> void:
	_casting = active
	_active_slot = slot
	_refresh()


func _on_spell_equipped(slot: int, _spell: CastInputPanel.Spell) -> void:
	_equipped_slots[slot] = true
	_refresh()


func _on_spell_sequence_changed(sequence: Array[StringName]) -> void:
	_sequence_complete = CastInputPanel.find_complete_spell(sequence) != null
	_refresh()


func _on_spell_reset() -> void:
	_equipped_slots = [false, false]
	_refresh()


func _refresh() -> void:
	var known_count := CastInputPanel.known_spells.size()
	var single := known_count == 1
	visible = known_count >= min_known_spells or Engine.is_editor_hint()
	var text: String
	if _casting:
		text = release_text if _sequence_complete else draw_text
		text = text.replace("{HOLD}", "{%s}" % CastInputPanel.HOLD_LABELS[_active_slot])
	else:
		if true in _equipped_slots: text = equipped_text_single if single else equipped_text
		else: text = prepare_text_single if single else prepare_text
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
