extends Node


@onready var player: Player = %PlayerCharacter


func _ready() -> void:
	player.hide_spell_area()
	GameUIBridge.spell_ready.connect(_on_spell_ready)
	GameUIBridge.spell_reset.connect(_on_spell_reset)
	GameUIBridge.spell_casted.connect(_on_spell_casted)


func _on_spell_ready(spell: CastInputPanel.Spell) -> void:
	print("ready ", CastInputPanel.SPELL_LABELS[spell])
	if spell == CastInputPanel.Spell.ATTACK_AREA:
		player.show_spell_area()
	if spell == CastInputPanel.Spell.ATTACK_AREA:
		player.show_spell_area()


func _on_spell_reset() -> void:
	player.hide_spell_area()


func _on_spell_casted(spell: CastInputPanel.Spell) -> void:
	print("casted ", CastInputPanel.SPELL_LABELS[spell])
	if spell == CastInputPanel.Spell.ATTACK_AREA:
		var targets := player.get_spell_area_bodies()
		print(targets)
		if targets.is_empty(): return
		for target in targets:
			if not target.is_in_group("enemies"): return
			target.take_damage(50.0)
