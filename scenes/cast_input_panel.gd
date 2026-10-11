@tool
class_name CastInputPanel
extends Control


enum Spell { ATTACK_TARGET, ATTACK_AREA, SHIELD, HEAL, MAGIC_MISSILE, MISTY_STEP }
enum SpellDirection { UP, DOWN, LEFT, RIGHT }


const SPELL_LABELS: Dictionary[Spell, String] = {
	Spell.ATTACK_TARGET: "Sacred Flame",
	Spell.ATTACK_AREA: "Word of Radiance",
	Spell.SHIELD: "Shield of Faith",
	Spell.HEAL: "Healing Word",
	Spell.MAGIC_MISSILE: "Magic Missile",
	Spell.MISTY_STEP: "Misty Step"
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
	# Spell.ATTACK_AREA: [
	# 	SPELL_ACTIONS[SpellDirection.DOWN],
	# 	SPELL_ACTIONS[SpellDirection.LEFT],
	# 	SPELL_ACTIONS[SpellDirection.UP]
	# ],
	# Spell.SHIELD: [
	# 	SPELL_ACTIONS[SpellDirection.RIGHT],
	# 	SPELL_ACTIONS[SpellDirection.UP],
	# 	SPELL_ACTIONS[SpellDirection.LEFT]
	# ],
	# Spell.HEAL: [
	# 	SPELL_ACTIONS[SpellDirection.RIGHT],
	# 	SPELL_ACTIONS[SpellDirection.DOWN],
	# 	SPELL_ACTIONS[SpellDirection.LEFT]
	# ]
	Spell.MAGIC_MISSILE: [
		SPELL_ACTIONS[SpellDirection.DOWN],
		SPELL_ACTIONS[SpellDirection.UP]
	],
	Spell.MISTY_STEP: [
		SPELL_ACTIONS[SpellDirection.UP],
		SPELL_ACTIONS[SpellDirection.DOWN]
	],
}

const CAST_COOLDOWN = 0.3
const SPELL_COOLDOWNS: Dictionary[Spell, float] = {
	Spell.MAGIC_MISSILE: 1.0,
	Spell.MISTY_STEP: 0.5
}

const SLOT_COUNT = 2
const HOLD_ACTIONS: Array[StringName] = [&"cast_hold", &"cast_hold_secondary"]
const FIRE_ACTIONS: Array[StringName] = [&"basic_attack", &"cast_secondary"]
const HOLD_LABELS: Array[String] = ["LT", "LB"]
const FIRE_LABELS: Array[String] = ["RT", "RB"]


var spell_sequence: Array[StringName] = []
var casting := false
var spells_unlocked := false: set = _set_spells_unlocked
var _slot_spells: Array = [null, null]
var _active_slot := 0
var _drawn_this_hold := false
var _has_wand := false
var _alive := true
var _cast_timers: Array[Timer] = []


@onready var button_container: HBoxContainer = %ButtonContainer
@onready var prompt_container_left_spacer: Control = %PromptContainerLeftSpacer
@onready var prompt_container: VBoxContainer = %PromptContainer
@onready var button_container_left_spacer: Control = %ButtonContainerLeftSpacer
@onready var button_box: HBoxContainer = %ButtonBox


func _ready() -> void:
	_clear_spell_sequence()
	button_container_left_spacer.resized.connect(_update_prompt_position)
	if Engine.is_editor_hint(): return
	for slot in SLOT_COUNT:
		var timer := Timer.new()
		timer.one_shot = true
		timer.timeout.connect(_on_cast_timer_timeout.bind(slot))
		add_child(timer)
		_cast_timers.append(timer)
	set_process_input(false)	# locked until the wand is collected
	set_physics_process(false)
	GameUIBridge.inventory_changed.connect(_on_inventory_changed)
	GameUIBridge.player_alive_changed.connect(_on_player_alive_changed)
	GameUIBridge.level_ready.connect(_on_level_ready)


func _notification(what: int) -> void:
	if what != NOTIFICATION_UNPAUSED: return
	if casting and not Input.is_action_pressed(HOLD_ACTIONS[_active_slot]): _end_casting()


func _set_spells_unlocked(new_value: bool) -> void:
	if new_value == spells_unlocked: return
	spells_unlocked = new_value
	set_process_input(spells_unlocked)
	set_physics_process(spells_unlocked)
	if spells_unlocked:
		for slot in SLOT_COUNT:
			if Input.is_action_pressed(HOLD_ACTIONS[slot]): return _begin_casting(slot)
		return
	var was_casting := casting
	casting = false
	_clear_spell_sequence()
	_unequip_all()
	if was_casting: GameUIBridge.cast_mode_changed.emit(false, _active_slot)


func _on_inventory_changed(items: Array[Player.Item]) -> void:
	_has_wand = Player.Item.WAND in items
	_refresh_unlock()


func _on_player_alive_changed(alive: bool) -> void:
	_alive = alive
	_refresh_unlock()


func _on_level_ready() -> void:
	for slot in SLOT_COUNT:
		if _cast_timers[slot].is_stopped(): _equip(slot)


func _refresh_unlock() -> void:
	spells_unlocked = _has_wand and _alive


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint(): return
	for slot in SLOT_COUNT:
		if Input.is_action_just_pressed(HOLD_ACTIONS[slot]):
			_begin_casting(slot)
		elif casting and slot == _active_slot and Input.is_action_just_released(HOLD_ACTIONS[slot]):
			_end_casting()
		if Input.is_action_just_pressed(FIRE_ACTIONS[slot]): _cast_slot(slot)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"reset_cast"):
		_clear_spell_sequence()
		return _unequip_all()

	if not casting: return

	for action in SPELL_ACTIONS.values():
		if event.is_action_pressed(action):
			_append_to_spell_sequence(action)


func _begin_casting(slot: int) -> void:
	_active_slot = slot
	_drawn_this_hold = false
	_clear_spell_sequence()
	casting = true
	GameUIBridge.cast_mode_changed.emit(true, slot)


func _end_casting() -> void:
	var other := (_active_slot + 1) % SLOT_COUNT
	if Input.is_action_pressed(HOLD_ACTIONS[other]): return _begin_casting(other)
	casting = false
	GameUIBridge.cast_mode_changed.emit(false, _active_slot)


func _cast_slot(slot: int) -> void:
	var spell = _slot_spells[slot]
	if spell == null: return
	if not _cast_timers[slot].is_stopped(): return
	GameUIBridge.spell_casted.emit(slot, spell)
	var cooldown: float = SPELL_COOLDOWNS.get(spell, CAST_COOLDOWN)
	_cast_timers[slot].start(cooldown)
	GameUIBridge.cast_cooldown_started.emit(slot, cooldown)


func _on_cast_timer_timeout(slot: int) -> void:
	_equip(slot)


func _clear_spell_sequence() -> void:
	spell_sequence.clear()
	_update_prompt([
		Spell.ATTACK_TARGET,
		# Spell.ATTACK_AREA,
		# Spell.SHIELD,
		# Spell.HEAL
		Spell.MAGIC_MISSILE,
		Spell.MISTY_STEP,
	])
	_update_button_box()
	if not Engine.is_editor_hint(): GameUIBridge.spell_sequence_changed.emit(spell_sequence)


func _unequip_all() -> void:
	_slot_spells = [null, null]
	if not Engine.is_editor_hint(): GameUIBridge.spell_reset.emit()


func _append_to_spell_sequence(action: StringName) -> void:
	spell_sequence.append(action)

	var spells = _find_matching_spells()
	if spells.is_empty():
		print("spell does not exist")
		spell_sequence.pop_back()
	else:
		_continue_casting(spells)


func _find_matching_spells() -> Array[Spell]:
	var matching_spells: Array[Spell]
	for spell in SPELL_SEQUENCES:
		var sequence_definition = SPELL_SEQUENCES[spell]
		if _is_spell_matching(sequence_definition): matching_spells.append(spell)
	return matching_spells


func _find_complete_spell() -> Variant:
	return find_complete_spell(spell_sequence)


static func spells_for_next_action(sequence: Array[StringName], action: StringName) -> Array[Spell]:
	var result: Array[Spell] = []
	var sequence_size := sequence.size()
	for spell in SPELL_SEQUENCES:
		var definition: Array = SPELL_SEQUENCES[spell]
		if definition.size() <= sequence_size: continue
		if definition.slice(0, sequence_size) != sequence: continue
		if definition[sequence_size] == action: result.append(spell)
	return result


static func find_complete_spell(sequence: Array[StringName]) -> Variant:
	for spell in SPELL_SEQUENCES:
		if SPELL_SEQUENCES[spell] == sequence: return spell
	return null


func _is_spell_matching(spell: Array) -> bool:
	return spell.slice(0, spell_sequence.size()) == spell_sequence


func _continue_casting(spells: Array[Spell]) -> void:
	_update_button_box()
	_update_prompt(spells)
	_check_complete_spell()
	GameUIBridge.spell_sequence_changed.emit(spell_sequence)


func _check_complete_spell() -> void:
	var complete_spell = _find_complete_spell()
	if complete_spell == null or _drawn_this_hold: return
	_drawn_this_hold = true
	if complete_spell == _slot_spells[_active_slot]: return
	_slot_spells[_active_slot] = complete_spell
	if _cast_timers[_active_slot].is_stopped(): _equip(_active_slot)


func _equip(slot: int) -> void:
	if _slot_spells[slot] == null: return
	GameUIBridge.spell_equipped.emit(slot, _slot_spells[slot])


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
		if SPELL_SEQUENCES[spell].size() == sequence_size:
			sequence_text += FIRE_LABELS[_active_slot]

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
