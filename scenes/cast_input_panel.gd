@tool
extends MarginContainer


enum Spell {ATTACK_TARGET, ATTACK_AREA, SHIELD, HEAL}
enum SpellDirection {UP, DOWN, LEFT, RIGHT}


const SPELL_LABELS: Dictionary[Spell, String] = {
	Spell.ATTACK_TARGET: "Attack Target",
	Spell.ATTACK_AREA: "Attack Area",
	Spell.SHIELD: "Shield",
	Spell.HEAL: "Heal"
}


const SPELL_ACTIONS: Dictionary[SpellDirection, StringName] = {
	SpellDirection.UP: &"cast_up",
	SpellDirection.DOWN: &"cast_down",
	SpellDirection.LEFT: &"cast_left",
	SpellDirection.RIGHT: &"cast_right"
}


const SPELL_DIRECTION_LABELS: Dictionary[StringName, String] = {
	SPELL_ACTIONS[SpellDirection.UP]: "X",
	SPELL_ACTIONS[SpellDirection.DOWN]: "B",
	SPELL_ACTIONS[SpellDirection.LEFT]: "Y",
	SPELL_ACTIONS[SpellDirection.RIGHT]: "A"
}


const SPELL_SEQUENCES: Dictionary[Spell, Array] = {
	Spell.ATTACK_TARGET: [
		SPELL_ACTIONS[SpellDirection.DOWN],
		SPELL_ACTIONS[SpellDirection.RIGHT],
		SPELL_ACTIONS[SpellDirection.UP]
	],
	Spell.ATTACK_AREA: [
		SPELL_ACTIONS[SpellDirection.DOWN],
		SPELL_ACTIONS[SpellDirection.LEFT],
		SPELL_ACTIONS[SpellDirection.UP]
	],
	Spell.SHIELD: [
		SPELL_ACTIONS[SpellDirection.RIGHT],
		SPELL_ACTIONS[SpellDirection.UP],
		SPELL_ACTIONS[SpellDirection.LEFT]
	],
	Spell.HEAL: [
		SPELL_ACTIONS[SpellDirection.RIGHT],
		SPELL_ACTIONS[SpellDirection.DOWN],
		SPELL_ACTIONS[SpellDirection.LEFT]
	]
}


var spell_sequence := []


@onready var button_container: HBoxContainer = %ButtonContainer
@onready var prompt_container_left_spacer: Control = %PromptContainerLeftSpacer
@onready var prompt_container: VBoxContainer = %PromptContainer
@onready var button_container_left_spacer: Control = %ButtonContainerLeftSpacer
@onready var button_box: HBoxContainer = %ButtonBox


func _ready() -> void:
	_clear_spell_sequence()


func _input(event: InputEvent) -> void:
	for action in SPELL_ACTIONS.values():
		if event.is_action_pressed(action):
			print("adding " + action)
			return _append_to_spell_sequence(action)

	if event.is_action_pressed(&"reset_cast"):
		_clear_spell_sequence()


func _clear_spell_sequence(with_signal := true) -> void:
	spell_sequence.clear()
	_update_prompt([Spell.ATTACK_TARGET, Spell.ATTACK_AREA, Spell.SHIELD, Spell.HEAL])
	_update_button_box()

	# if with_signal: spell_sequence_cleared.emit()



func _append_to_spell_sequence(action: StringName) -> void:
	spell_sequence.append(action)

	var spells = _find_matching_spells()
	if spells.is_empty():
		print("spell does not exist")
		# show error 
		spell_sequence.pop_back()
		pass
	else:
		_continue_casting(spells)


func _find_matching_spells() -> Array[Spell]:
	var matching_spells: Array[Spell]
	for spell in SPELL_SEQUENCES:
		var sequence_definition = SPELL_SEQUENCES[spell]
		if _is_spell_matching(sequence_definition): matching_spells.append(spell)
	return matching_spells


func _is_spell_matching(spell: Array) -> bool:
	return spell.slice(0, spell_sequence.size()) == spell_sequence


func _continue_casting(spells: Array[Spell]) -> void:
	print("continued casting")
	_update_button_box()
	_update_prompt(spells)
	pass
	# var current_sequence_size = spell_sequence.size()
	
	# if SpellDefinitions.get_spell_sequence(spell).size() == current_sequence_size:
	# 	_on_spell_casted(spell)
	# 	clear_spell_sequence(false)
	# else:
	# 	spell_in_progress.emit(spell, current_sequence_size)


func _update_button_box() -> void:
	for node in button_box.get_children():
		var label: Label = node.get_child(0)
		label.text = ""

	for index in spell_sequence.size():
		var label: Label = button_box.get_child(index).get_child(0)
		label.text = SPELL_DIRECTION_LABELS[spell_sequence[index]]


func _update_prompt(spells: Array[Spell]) -> void:
	for child in prompt_container.get_children(): child.queue_free()
	_update_prompt_text(spells)
	_update_prompt_position()


func _update_prompt_text(spells: Array[Spell]) -> void:
	var sequence_size = spell_sequence.size()

	for spell in spells:
		var sequence_text: String = ""
		for action in SPELL_SEQUENCES[spell].slice(sequence_size):
			sequence_text += SPELL_DIRECTION_LABELS[action]

		var label := Label.new()
		label.text = "{sequence}: {spell}".format(
			{ "sequence": sequence_text, "spell": SPELL_LABELS[spell] }
		)
		label.add_theme_font_size_override(&"font_size", 32)
		prompt_container.add_child(label)

func _update_prompt_position() -> void:
	var button_separation = button_container.get_theme_constant("separation")
	var horizontal_offset = button_separation + spell_sequence.size() * (button_separation + 80.0)
	prompt_container_left_spacer.custom_minimum_size = Vector2(button_container_left_spacer.size.x + horizontal_offset, 0)


func _on_button_container_left_spacer_resized() -> void:
	_update_prompt_position()
