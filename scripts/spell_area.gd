extends Area2D


const CAST_FADEOUT_DURATION = 0.25


@onready var spell_area_sprite = %SpellAreaSprite


func animate(spell: SpellDefinitions.Spell, callback: Callable) -> void:
	var tween := create_tween()
	_reveal(spell, tween)
	tween.tween_callback(callback)
	_fadeout(spell, tween)
	tween.tween_callback(func(): queue_free())


func _reveal(spell: SpellDefinitions.Spell, tween: Tween) -> void:
	var spell_area_sprite_scale = spell_area_sprite.scale
	spell_area_sprite.scale = Vector2.ZERO
	tween \
		.tween_property(
			spell_area_sprite,
			"scale",
			spell_area_sprite_scale,
			SpellSystem.CAST_DURATION
		).from_current()

	tween \
		.parallel() \
		.tween_property(
			spell_area_sprite,
			"modulate",
			SpellDefinitions.SPELL_AREA_COLORS[spell],
			SpellSystem.CAST_DURATION
		).from_current()


func _fadeout(spell: SpellDefinitions.Spell, tween: Tween) -> void:
	var transparency_difference: Color = Color(0, 0, 0, SpellDefinitions.SPELL_COLOR_TRANSPARENCY)
	
	tween \
		.tween_property(
			spell_area_sprite,
			"modulate",
			SpellDefinitions.SPELL_AREA_COLORS[spell] - transparency_difference,
			CAST_FADEOUT_DURATION
		).from(SpellDefinitions.SPELL_AREA_COLORS[spell])
