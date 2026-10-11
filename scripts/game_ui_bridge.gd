extends Node

@warning_ignore("unused_signal")
signal health_changed
@warning_ignore("unused_signal")
signal room_changed
@warning_ignore("unused_signal")
signal spell_unlocked
@warning_ignore("unused_signal")
signal spell_reset()
@warning_ignore("unused_signal")
signal spell_equipped(slot: int, spell: CastInputPanel.Spell)
@warning_ignore("unused_signal")
signal spell_casted(slot: int, spell: CastInputPanel.Spell)
@warning_ignore("unused_signal")
signal cast_cooldown_started(slot: int, duration: float)
@warning_ignore("unused_signal")
signal spell_sequence_changed(sequence: Array[StringName])
@warning_ignore("unused_signal")
signal cast_mode_changed(active: bool, slot: int)
@warning_ignore("unused_signal")
signal shield_changed(active: bool)
@warning_ignore("unused_signal")
signal inventory_changed(items: Array[Player.Item])
@warning_ignore("unused_signal")
signal player_alive_changed(alive: bool)
@warning_ignore("unused_signal")
signal level_ready

