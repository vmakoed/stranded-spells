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


const ACTION_GLYPHS: Dictionary[StringName, String] = {
	&"cast_up": "FACE_TOP",
	&"cast_down": "FACE_BOTTOM",
	&"cast_left": "FACE_LEFT",
	&"cast_right": "FACE_RIGHT",
}


@export var spell: CastInputPanel.Spell:
	set(value):
		spell = value
		if is_node_ready(): _refresh()
@export_multiline var prepare_text := "Hold {HOLD}"
@export_multiline var draw_text := "{GLYPHS}: draw glyph"
@export_multiline var release_text := "Release {HOLD}"
@export_multiline var equipped_text := "{RS}: aim {FIRE}: cast"
@export_multiline var slots_text := "Up to 2 spells can be equipped"


var _casting := false
var _active_slot := 0
var _spell_slot := -1
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
	GameUIBridge.spell_unequipped.connect(_on_spell_unequipped)
	GameUIBridge.spell_sequence_changed.connect(_on_spell_sequence_changed)
	_refresh()


func _on_spells_changed(_spells: Array[CastInputPanel.Spell]) -> void:
	_refresh()


func _on_cast_mode_changed(active: bool, slot: int) -> void:
	_casting = active
	_active_slot = slot
	_refresh()


func _on_spell_equipped(slot: int, equipped: CastInputPanel.Spell) -> void:
	if equipped == spell: _spell_slot = slot
	elif slot == _spell_slot: _spell_slot = -1
	_refresh()


func _on_spell_unequipped(slot: int) -> void:
	if slot == _spell_slot: _spell_slot = -1
	_refresh()


func _on_spell_sequence_changed(sequence: Array[StringName]) -> void:
	_sequence_complete = CastInputPanel.find_complete_spell(sequence) == spell
	_refresh()


func _on_spell_reset() -> void:
	_spell_slot = -1
	_refresh()


func _refresh() -> void:
	visible = Engine.is_editor_hint() or CastInputPanel.is_known(spell)
	var text: String
	if _casting:
		text = release_text if _sequence_complete else draw_text
		text = text.replace("{HOLD}", "{%s}" % CastInputPanel.HOLD_LABELS[_active_slot])
	elif _spell_slot >= 0:
		text = equipped_text.replace("{FIRE}", "{%s}" % CastInputPanel.FIRE_LABELS[_spell_slot])
	else:
		text = prepare_text.replace("{HOLD}", _prepare_holds())
		if _prior_spells() > 0: text += "\n" + slots_text
	text = text.replace("{GLYPHS}", _glyphs())
	if text == _shown_text: return
	_shown_text = text
	_build(text)


func _prior_spells() -> int:
	if Engine.is_editor_hint(): return 0
	return CastInputPanel.known_spells.size() - 1


func _prepare_holds() -> String:
	if _prior_spells() <= 0: return "{%s}" % CastInputPanel.HOLD_LABELS[0]
	return "{%s} or {%s}" % CastInputPanel.HOLD_LABELS


func _glyphs() -> String:
	var tokens: PackedStringArray = []
	for action in CastInputPanel.SPELL_SEQUENCES.get(spell, []):
		tokens.append("{%s}" % ACTION_GLYPHS[action])
	return " ".join(tokens)


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
