class_name CastTutorial
extends Node


const GLYPHS: Dictionary[StringName, Texture2D] = {
	&"cast_up": preload("res://resources/prompt_face_top.tres"),
	&"cast_right": preload("res://resources/prompt_face_right.tres"),
	&"cast_down": preload("res://resources/prompt_face_bottom.tres"),
	&"cast_left": preload("res://resources/prompt_face_left.tres"),
}
const LT: Texture2D = preload("res://resources/prompt_lt.tres")
const HOLD_TEXT = "Hold"
const PRESS_TEXT = "Press"
const RELEASE_TEXT = "Release"


@export var player: Player
@export var target: Node2D
@export var item := Player.Item.BOOK
@export var spell := CastInputPanel.Spell.ATTACK_TARGET


var _active := false
var _casting := false
var _sequence: Array[StringName] = []
var _expected: Array = []
var _dim: TutorialDim


func _ready() -> void:
	if is_instance_valid(player) and player.has_item(item):
		queue_free()
		return
	_expected = CastInputPanel.SPELL_SEQUENCES[spell]
	GameUIBridge.inventory_changed.connect(_on_inventory_changed)
	GameUIBridge.cast_mode_changed.connect(_on_cast_mode_changed)
	GameUIBridge.spell_sequence_changed.connect(_on_spell_sequence_changed)
	GameUIBridge.spell_reset.connect(_on_spell_reset)
	GameUIBridge.spell_previewed.connect(_on_spell_previewed)
	GameUIBridge.spell_casted.connect(_on_spell_casted)


func _exit_tree() -> void:
	if _active: GameUIBridge.cast_action_required.emit(&"")


func _on_inventory_changed(items: Array[Player.Item]) -> void:
	if not _active and item in items: _start()
	elif _active and item not in items: _finish()


func _start() -> void:
	if not is_instance_valid(player): return
	_active = true
	if is_instance_valid(target):
		player.aim_angle = (target.global_position - player.global_position).angle()
	else:
		player.aim_angle = -PI / 2.0
	player.aim_sprite.visible = true
	player.set_physics_process(false)
	_dim = TutorialDim.new()
	get_parent().add_child(_dim)
	_dim.raise([player, target])
	_refresh()


func _refresh() -> void:
	if not _active or not is_instance_valid(player): return
	var step := _sequence.size()
	var complete := step >= _expected.size()
	var gate: StringName = &""
	if not complete: gate = _expected[step]
	var row: Dictionary
	if not _casting:
		row = { "icon": LT, "text": HOLD_TEXT }
	elif complete:
		row = { "icon": LT, "text": RELEASE_TEXT }
	else:
		row = { "icon": GLYPHS[gate], "text": PRESS_TEXT }
	GameUIBridge.cast_action_required.emit(gate)
	player.hint.show_prompts([row], -1.0)


func _on_cast_mode_changed(active: bool) -> void:
	_casting = active
	_refresh()


func _on_spell_sequence_changed(sequence: Array[StringName]) -> void:
	_sequence = sequence.duplicate()
	_refresh()


func _on_spell_reset() -> void:
	_sequence = []
	_refresh()


func _on_spell_previewed(preview: Node2D) -> void:
	if _active and is_instance_valid(_dim): _dim.raise([preview])


func _on_spell_casted(cast: CastInputPanel.Spell) -> void:
	if _active and cast == spell: _finish()


func _finish() -> void:
	if not _active: return
	_active = false
	GameUIBridge.cast_action_required.emit(&"")
	if is_instance_valid(player):
		player.hint.dismiss()
		player.aim_sprite.visible = player.has_item(Player.Item.WAND)
		player.set_physics_process(true)
	if is_instance_valid(_dim): _dim.dismiss()
	queue_free()
