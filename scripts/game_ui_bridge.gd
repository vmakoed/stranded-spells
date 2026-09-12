extends Node

@warning_ignore("unused_signal")
signal health_changed
@warning_ignore("unused_signal")
signal room_changed
@warning_ignore("unused_signal")
signal spell_unlocked
@warning_ignore("unused_signal")
signal spell_ready(spell: CastInputPanel.Spell)
@warning_ignore("unused_signal")
signal spell_reset()
@warning_ignore("unused_signal")
signal spell_casted(spell: CastInputPanel.Spell)
@warning_ignore("unused_signal")
signal spell_sequence_changed(sequence: Array[StringName])
@warning_ignore("unused_signal")
signal cast_mode_changed(active: bool)
@warning_ignore("unused_signal")
signal shield_changed(active: bool)
@warning_ignore("unused_signal")
signal inventory_changed(items: Array[Player.Item])

