class_name SpellDefinitions


enum Spell {PUSH, FROST, SHOCK, FIRE}
enum SpellDirection {UP, DOWN, LEFT, RIGHT}


const SPELL_ACTIONS: Dictionary[SpellDirection, StringName] = {
	SpellDirection.UP: &"cast_up",
	SpellDirection.DOWN: &"cast_down",
	SpellDirection.LEFT: &"cast_left",
	SpellDirection.RIGHT: &"cast_right"
}

const SPELL_SEQUENCES: Dictionary[Spell, Array] = {
	Spell.PUSH: [
		SPELL_ACTIONS[SpellDirection.DOWN],
		SPELL_ACTIONS[SpellDirection.DOWN]
	],
	Spell.FROST: [
		SPELL_ACTIONS[SpellDirection.LEFT],
		SPELL_ACTIONS[SpellDirection.UP],
		SPELL_ACTIONS[SpellDirection.RIGHT],
		SPELL_ACTIONS[SpellDirection.DOWN],	
	],
    Spell.SHOCK: [
        SPELL_ACTIONS[SpellDirection.UP],
        SPELL_ACTIONS[SpellDirection.LEFT],
        SPELL_ACTIONS[SpellDirection.RIGHT],
        SPELL_ACTIONS[SpellDirection.DOWN], 
    ],
    Spell.FIRE: [
        SPELL_ACTIONS[SpellDirection.RIGHT],
        SPELL_ACTIONS[SpellDirection.DOWN],
        SPELL_ACTIONS[SpellDirection.UP],
        SPELL_ACTIONS[SpellDirection.DOWN],
        SPELL_ACTIONS[SpellDirection.LEFT], 
    ]
}

const ROOM_WIDE_SPELLS = [Spell.SHOCK]
const SPELL_RECEIVING_METHODS: Dictionary[Spell, StringName] = {
    Spell.PUSH: &"receive_push",
    Spell.FROST: &"receive_frost",
    Spell.SHOCK: &"receive_shock",
    Spell.FIRE: &"receive_fire"
}

const SPELL_COLOR_TRANSPARENCY =  0.19

const SPELL_AREA_COLORS: Dictionary[Spell, Color] = {
    Spell.PUSH: Color(1, 1, 1, SPELL_COLOR_TRANSPARENCY),
    Spell.FROST: Color(0, 1, 1, SPELL_COLOR_TRANSPARENCY),
    Spell.SHOCK: Color(1, 1, 0, SPELL_COLOR_TRANSPARENCY),
    Spell.FIRE: Color(1, 0, 0, SPELL_COLOR_TRANSPARENCY),
}

const SPELL_ENEMY_COLORS: Dictionary[Spell, Color] = {
    Spell.PUSH: Color.WHITE,
    Spell.FROST: Color.CYAN,
    Spell.SHOCK: Color.YELLOW,
    Spell.FIRE: Color.RED
}


static func get_spell_sequence(spell: Spell) -> Array:
    return SPELL_SEQUENCES[spell]
