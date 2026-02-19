class_name SpellDefinitions

enum SpellDirection {UP, DOWN, LEFT, RIGHT}
enum Spell {PUSH, FROST}

const SPELL_ACTIONS: Dictionary[SpellDirection, StringName] = {
	SpellDirection.UP: &"cast_up",
	SpellDirection.DOWN: &"cast_down",
	SpellDirection.LEFT: &"cast_left",
	SpellDirection.RIGHT: &"cast_right"
}

const SPELLS: Dictionary[Spell, Array] = {
	Spell.PUSH: [
		SPELL_ACTIONS[SpellDirection.DOWN],
		SPELL_ACTIONS[SpellDirection.DOWN]
	],
	Spell.FROST: [
		SPELL_ACTIONS[SpellDirection.LEFT],
		SPELL_ACTIONS[SpellDirection.UP],
		SPELL_ACTIONS[SpellDirection.RIGHT],
		SPELL_ACTIONS[SpellDirection.DOWN],	
	]
}
