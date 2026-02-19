extends Node


signal push_casted
signal frost_casted


var spell_sequence := []
var spells: Array
var spell_starter_actions: Array


func _ready() -> void:
	spells = SpellDefinitions.SPELLS.values()
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
	match spell:
		SpellDefinitions.SPELLS[SpellDefinitions.Spell.PUSH]: push_casted.emit()
		SpellDefinitions.SPELLS[SpellDefinitions.Spell.FROST]: frost_casted.emit()
