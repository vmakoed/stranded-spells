extends Node


signal spell_in_progress
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

	var spell = _find_matching_spell()
	if spell == null:
		_restart_casting(action)
	else:
		_continue_casting(spell)


func _continue_casting(spell: SpellDefinitions.Spell) -> void:
	var current_sequence_size = spell_sequence.size()
	
	if SpellDefinitions.get_spell_sequence(spell).size() == current_sequence_size:
		_on_spell_casted(spell)
		spell_sequence.clear()
	else:
		spell_in_progress.emit(spell, current_sequence_size)

func _restart_casting(action) -> void:
	if action in spell_starter_actions:
		spell_sequence.clear()
		append_to_spell_sequence(action)


func _is_spell_matching(spell: Array) -> bool:
	return spell.slice(0, spell_sequence.size()) == spell_sequence


func _find_matching_spell() -> Variant:
	for spell in SpellDefinitions.SPELL_SEQUENCES:
		var sequence_definition = SpellDefinitions.SPELL_SEQUENCES[spell]
		if _is_spell_matching(sequence_definition): return spell

	return null


func _on_spell_casted(spell: SpellDefinitions.Spell) -> void:
	spell_casted.emit(spell)
