extends Node


var box_motion: Vector2


@onready var player: CharacterBody2D = %PlayerCharacter
@onready var boxes: Node = %Boxes


var spell_sequence = []
var push_spell : Array[StringName] = [&"cast_down", &"cast_down"]
var another_spell : Array[StringName] = [&"interact", &"cast_down"]
var spells : Array[Array] = [push_spell, another_spell] # TODO: make spells objects instead


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"cast_down"):
		_append_to_spell_sequence(&"cast_down")

	if event.is_action_pressed(&"interact"):
		_append_to_spell_sequence(&"interact")


## [code]action[/code] must start or continue a spell sequence
func _append_to_spell_sequence(action: StringName) -> void:
	spell_sequence.append(action)
	var matching_spell_index = spells.find_custom(_is_spell_matching.bind())

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
	spell_sequence.clear()
	_append_to_spell_sequence(action)


func _is_spell_matching(spell: Array[StringName]) -> bool:
	return spell.slice(0, spell_sequence.size()) == spell_sequence


func _on_spell_casted(spell) -> void:
	match spell:
		push_spell: _on_push_casted()


func _on_push_casted() -> void:
	for spell_receiver: Node2D in player.get_spell_receivers():
		spell_receiver.receive_push( \
			player. \
				global_position. \
				direction_to(spell_receiver.global_position). \
				normalized() \
		)
