extends Area2D


@export var spell: SpellDefinitions.Spell


func _ready() -> void:
	if not spell: return
	if GameState.get_spell_unlocks()[spell]: queue_free()


func _on_body_entered(body: Node2D) -> void:
	if not spell: return
	if not body is Player: return
	body.play_pickup_sound()
	GameState.unlock_spell(spell)
	GameUIBridge.spell_unlocked.emit()
	queue_free()
