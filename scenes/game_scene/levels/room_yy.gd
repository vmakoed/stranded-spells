extends Node


signal level_lost


const SPELL_AREA_ANIMATION_DURATION = 0.5
const SPELL_AREA_DAMAGE = 50.0
const SPELL_PROJECTILE_SPEED = 160.0
const SPELL_PROJECTILE_OFFSET = 16.0


@export var projectile_scene := preload("res://scenes/spell_projectile_area.tscn")


@onready var player: Player = %PlayerCharacter
@onready var spell_area_sprite = %SpellAreaSprite
@onready var magic_circle: MagicCircle = %MagicCircleNode


var _preview_projectile: SpellProjectile


func _ready() -> void:
	player.hide_spell_area()
	player.destroyed.connect(func():
		print("destroyed")
		_dismiss_preview_projectile()
		level_lost.emit()
	)
	GameUIBridge.spell_ready.connect(_on_spell_ready)
	GameUIBridge.spell_reset.connect(_on_spell_reset)
	GameUIBridge.spell_casted.connect(_on_spell_casted)
	GameUIBridge.spell_sequence_changed.connect(_on_spell_sequence_changed)
	GameUIBridge.cast_mode_changed.connect(_on_cast_mode_changed)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy.has_signal("died"): continue
		enemy.died.connect(_on_enemy_new_died.bind(enemy))


func _damage_targets_in_area() -> void:
	var targets := player.get_spell_area_areas()
	print(targets)	# TODO: remove spell area from player? / area is kind of same as projectile?
	if targets.is_empty(): return
	for target in targets:
		if target is not HurtboxComponent: return
		target.damage(SPELL_AREA_DAMAGE)
	return


func _process(_delta: float) -> void:
	if _preview_projectile == null: return
	if not is_instance_valid(player):
		_preview_projectile = null
		return
	_place_projectile(_preview_projectile)


func _setup_projectile() -> SpellProjectile:
	var projectile := projectile_scene.instantiate() as SpellProjectile
	add_child(projectile)
	return projectile


func _spawn_origin() -> Vector2:
	return player.global_position + \
		Vector2(SPELL_PROJECTILE_OFFSET, 0.0).rotated(player.aim_angle)


func _place_projectile(projectile: SpellProjectile) -> void:
	projectile.global_position = _spawn_origin()
	projectile.rotation = player.aim_angle


func _dismiss_preview_projectile() -> void:
	if _preview_projectile == null: return
	if is_instance_valid(_preview_projectile):
		_preview_projectile.dismiss()
	_preview_projectile = null


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
		if _preview_projectile != null: return
		_preview_projectile = _setup_projectile()
		_place_projectile(_preview_projectile)
		_preview_projectile.manifest()
		return


func _on_spell_reset() -> void:
	player.hide_spell_area()
	player.aim_active = false
	magic_circle.clear_sequence()
	_dismiss_preview_projectile()


func _on_spell_casted(spell: CastInputPanel.Spell) -> void:
	if spell == CastInputPanel.Spell.ATTACK_AREA:
		_show_spell_area()
		_damage_targets_in_area()
		return
	if spell == CastInputPanel.Spell.ATTACK_TARGET:
		var projectile := _preview_projectile
		_preview_projectile = null
		if projectile == null or not is_instance_valid(projectile):
			projectile = _setup_projectile()
		_place_projectile(projectile)
		projectile.launch(Vector2.from_angle(player.aim_angle), SPELL_PROJECTILE_SPEED)
		return


func _on_enemy_new_died(enemy: Node) -> void:
	enemy.queue_free()


func _on_spell_sequence_changed(sequence: Array[StringName]) -> void:
	magic_circle.set_sequence(sequence)


func _on_cast_mode_changed(active: bool) -> void:
	magic_circle.visible = active
