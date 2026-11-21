class_name SpellEquipGate
extends Node


@export var spell: CastInputPanel.Spell
@export var player: Player
@export var icon: Texture2D = preload("res://assets/textures/inventory icon 193.png")
@export var pickup_delay := 0.5
@export var save_id := ""

var _released := false


func _ready() -> void:
	_teach.call_deferred()
	if GameState.get_flag(self, false): return
	GameUIBridge.spell_equipped.connect(_on_spell_equipped)
	_lock.call_deferred()


func _teach() -> void:
	if not is_instance_valid(player) or player.knows_spell(spell): return
	await get_tree().create_timer(pickup_delay).timeout
	if not is_instance_valid(player): return
	player.learn_spell(spell)
	player.play_pickup_sound()
	player.show_hint(icon)


func _lock() -> void:
	if _released or not is_instance_valid(player): return
	player.velocity = Vector2.ZERO
	player.set_physics_process(false)


func _on_spell_equipped(_slot: int, equipped: CastInputPanel.Spell) -> void:
	if _released or equipped != spell: return
	_released = true
	GameState.set_flag(self, true)
	GameUIBridge.spell_equipped.disconnect(_on_spell_equipped)
	if is_instance_valid(player): player.set_physics_process(true)
