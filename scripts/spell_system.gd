extends Node


signal spell_casted


var spell_sequence := []
var spells: Array
var spell_starter_actions: Array


func _ready() -> void:
	spells = SpellDefinitions.SPELL_SEQUENCES.values()
	spell_starter_actions = \
		spells.map(
			func(element: Array): return element.front()
		)


func append_to_spell_sequence(action: StringName) -> void:
	spell_sequence.append(action)
	var matching_spell_index = spells.find_custom(_is_spell_matching)

	if matching_spell_index >= 0:
		var spell = spells[matching_spell_index]
		_continue_casting(spell)
	else:
		_restart_casting(action)


func _continue_casting(spell: Array) -> void:
	if spell.size() == spell_sequence.size():
		_on_spell_casted(spell)
		spell_sequence.clear()


func _restart_casting(action) -> void:
	if action in spell_starter_actions:
		spell_sequence.clear()
		append_to_spell_sequence(action)


func _is_spell_matching(spell: Array) -> bool:
	return spell.slice(0, spell_sequence.size()) == spell_sequence


func _on_spell_casted(spell) -> void:
	spell_casted.emit(SpellDefinitions.SPELL_SEQUENCES.find_key(spell))
