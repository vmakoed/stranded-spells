extends Node


const SPELL_AREA_ANIMATION_DURATION = 0.5
const SPELL_AREA_DAMAGE = 50.0
const SPELL_PROJECTILE_SPEED = 320.0
const SPELL_PROJECTILE_OFFSET = 16.0


@export var projectile_scene := preload("res://scenes/spell_projectile_area.tscn")


@onready var player: Player = %PlayerCharacter
@onready var spell_area_sprite = %SpellAreaSprite


func _ready() -> void:
	player.hide_spell_area()
	GameUIBridge.spell_ready.connect(_on_spell_ready)
	GameUIBridge.spell_reset.connect(_on_spell_reset)
	GameUIBridge.spell_casted.connect(_on_spell_casted)


func _damage_targets_in_area() -> void:
	var targets := player.get_spell_area_bodies()	# TODO: remove spell area from player?
	if targets.is_empty(): return
	for target in targets:
		if not target.is_in_group("enemies"): return
		target.take_damage(SPELL_AREA_DAMAGE)
	return


func _launch_projectile(projectile: Node2D) -> void:
	projectile.velocity = Vector2.from_angle(player.aim_angle) * SPELL_PROJECTILE_SPEED


func _setup_projectile() -> Area2D:
	var projectile = projectile_scene.instantiate() as Area2D
	projectile.global_position = \
		player.global_position + \
			Vector2(SPELL_PROJECTILE_OFFSET, 0.0).rotated(player.aim_angle)
	projectile.rotation = player.aim_angle
	add_child(projectile)
	return projectile


func _show_projectile(projectile: Node2D) -> void:
	projectile.show()
	var tween = create_tween()
	tween.tween_property(
		projectile,
		"modulate",
		projectile.modulate,
		0.1
	).from(projectile.modulate - Color(0, 0, 0, 1.0))


func _show_spell_area() -> void:
	var initial_scale: Vector2 = spell_area_sprite.scale
	spell_area_sprite.show()

	var tween = create_tween()

	tween.tween_property(
		spell_area_sprite,
		"modulate",
		spell_area_sprite.modulate,
		0.2
	).from(spell_area_sprite.modulate - Color(0, 0, 0, 1.0))

	tween \
		.tween_property(
			spell_area_sprite,
			"scale",
			Vector2.ZERO,
			SPELL_AREA_ANIMATION_DURATION
		).from(initial_scale) \
		.set_trans(Tween.TRANS_EXPO)

	tween.tween_callback(func(): 
		spell_area_sprite.hide()
		spell_area_sprite.scale = initial_scale
	)


func _on_spell_ready(spell: CastInputPanel.Spell) -> void:
	print("ready ", CastInputPanel.SPELL_LABELS[spell])
	if spell == CastInputPanel.Spell.ATTACK_AREA:
		player.show_spell_area()
		return
	if spell == CastInputPanel.Spell.ATTACK_TARGET:
		player.aim_active = true
		return


func _on_spell_reset() -> void:
	player.hide_spell_area()
	player.aim_active = false


func _on_spell_casted(spell: CastInputPanel.Spell) -> void:
	if spell == CastInputPanel.Spell.ATTACK_AREA:
		_show_spell_area()
		_damage_targets_in_area()
		return
	if spell == CastInputPanel.Spell.ATTACK_TARGET:
		var projectile = _setup_projectile()
		_show_projectile(projectile)
		_launch_projectile(projectile)
		return
