extends Node


signal level_won(level_path : String)


@onready var player: CharacterBody2D = %PlayerCharacter
@onready var boxes: Node = %Boxes
@onready var door: Door = %Door


var spell_sequence = []
var spell_starter_actions = [&"cast_down"]
var push_spell: Array[StringName] = [&"cast_down", &"cast_down"]
var spells: Array[Array] = [push_spell]
var boxes_count : int


func _ready() -> void:
	boxes_count = boxes.get_child_count()

	for box: Box in boxes.get_children():
		box.destroyed.connect(_on_box_destroyed)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"cast_down"):
		_append_to_spell_sequence(&"cast_down")

	if event.is_action_pressed(&"interact"):
		_append_to_spell_sequence(&"interact")


func _append_to_spell_sequence(action: StringName) -> void:
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
		_append_to_spell_sequence(action)


func _is_spell_matching(spell: Array[StringName]) -> bool:
	return spell.slice(0, spell_sequence.size()) == spell_sequence


func _on_spell_casted(spell) -> void:
	match spell:
		push_spell: _on_push_casted()


func _on_push_casted() -> void:
	for spell_receiver: Node2D in player.get_spell_receivers():
		if spell_receiver.has_method(&"receive_push"):
			spell_receiver.receive_push( \
				player. \
					global_position. \
					direction_to(spell_receiver.global_position). \
					normalized() \
			)


func _on_box_destroyed() -> void:
	boxes_count -= 1

	if boxes_count == 0:
		door.open()


func _on_win_area_body_entered(body: Node2D) -> void:
	if body is Player:
		level_won.emit()
