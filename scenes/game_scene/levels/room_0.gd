extends Node


var box_motion: Vector2


@onready var player: CharacterBody2D = %PlayerCharacter
@onready var boxes: Node = %Boxes


var spell_sequence = []
var push_spell = [&"cast_down", &"cast_down"]


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"cast_down"):
		_append_to_spell_sequence(&"cast_down")

	if event.is_action_pressed(&"interact"):
		_append_to_spell_sequence(&"interact")


func _append_to_spell_sequence(action: StringName) -> void:
	spell_sequence.append(action)
	print(spell_sequence)

	if push_spell.slice(0, spell_sequence.size()) == spell_sequence:
		if push_spell.size() == spell_sequence.size():
			print("push casted")
			_on_push_casted()
			spell_sequence.clear()
		else:
			print("push in progress")
	else:
		spell_sequence.clear()

		if push_spell[0] == action:
			_append_to_spell_sequence(action)
	


func _on_push_casted() -> void:
	for spell_receiver: Node2D in player.get_spell_receivers():
		spell_receiver.receive_push( \
			player. \
				global_position. \
				direction_to(spell_receiver.global_position). \
				normalized() \
		)
