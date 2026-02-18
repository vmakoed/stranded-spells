extends Node


signal push_casted


var spell_sequence = []
var spell_starter_actions = [&"cast_down"]
var push_spell: Array[StringName] = [&"cast_down", &"cast_down"]
var spells: Array[Array] = [push_spell]


func append_to_spell_sequence(action: StringName) -> void:
	spell_sequence.append(action)
	var matching_spell_index = spells.find_custom(_is_spell_matching)

	if matching_spell_index >= 0:
		var spell = spells[matching_spell_index]
		_continue_casting(spell)
	else:
		_restart_casting(action)


func _continue_casting(spell: Array[StringName]) -> void:
	if spell.size() == spell_sequence.size():
		_on_spell_casted(spell)
		spell_sequence.clear()


func _restart_casting(action) -> void:
	if spell_starter_actions.has(action):
		spell_sequence.clear()
		append_to_spell_sequence(action)


func _is_spell_matching(spell: Array[StringName]) -> bool:
	return spell.slice(0, spell_sequence.size()) == spell_sequence


func _on_spell_casted(spell) -> void:
	match spell:
		push_spell: _on_push_casted()


func _on_push_casted() -> void:
	push_casted.emit()
