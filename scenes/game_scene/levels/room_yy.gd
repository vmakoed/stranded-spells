extends Node


signal level_lost


const SPELL_AREA_DAMAGE = 50.0
const SPELL_PROJECTILE_SPEED = 160.0
const SPELL_PROJECTILE_OFFSET = 16.0
const BASIC_ATTACK_SPEED = 220.0


@export var projectile_scene := preload("res://scenes/spell_projectile_area.tscn")
@export var area_burst_scene := preload("res://scenes/spell_area_burst.tscn")
@export var basic_projectile_scene := preload("res://scenes/basic_attack_projectile.tscn")


@onready var player: Player = %PlayerCharacter
@onready var magic_circle: MagicCircle = %MagicCircleNode


var _preview_spell: Node2D


func _ready() -> void:
	player.destroyed.connect(func():
		print("destroyed")
		_dismiss_preview_spell()
		level_lost.emit()
	)
	player.basic_attack_requested.connect(_on_basic_attack_requested)
	GameUIBridge.spell_ready.connect(_on_spell_ready)
	GameUIBridge.spell_reset.connect(_on_spell_reset)
	GameUIBridge.spell_casted.connect(_on_spell_casted)
	GameUIBridge.spell_sequence_changed.connect(_on_spell_sequence_changed)
	GameUIBridge.cast_mode_changed.connect(_on_cast_mode_changed)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy.has_signal("died"): continue
		enemy.died.connect(_on_enemy_new_died.bind(enemy))


func _process(_delta: float) -> void:
	if _preview_spell == null: return
	if not is_instance_valid(player):
		_preview_spell = null
		return
	_place_preview()


func _place_preview() -> void:
	if _preview_spell is SpellProjectile:
		_place_projectile(_preview_spell)
	else:
		_preview_spell.global_position = player.global_position


func _setup_projectile() -> SpellProjectile:
	var projectile := projectile_scene.instantiate() as SpellProjectile
	add_child(projectile)
	return projectile


func _setup_area_burst() -> SpellAreaBurst:
	var burst := area_burst_scene.instantiate() as SpellAreaBurst
	add_child(burst)
	burst.global_position = player.global_position
	return burst


func _spawn_origin() -> Vector2:
	return player.global_position + \
		Vector2(SPELL_PROJECTILE_OFFSET, 0.0).rotated(player.aim_angle)


func _place_projectile(projectile: SpellProjectile) -> void:
	projectile.global_position = _spawn_origin()
	projectile.rotation = player.aim_angle


func _dismiss_preview_spell() -> void:
	if _preview_spell == null: return
	if is_instance_valid(_preview_spell):
		_preview_spell.dismiss()
	_preview_spell = null


func _take_preview_spell() -> Node2D:
	var spell := _preview_spell
	_preview_spell = null
	if spell != null and not is_instance_valid(spell): return null
	return spell


func _on_spell_ready(spell: CastInputPanel.Spell) -> void:
	print("ready ", CastInputPanel.SPELL_LABELS[spell])
	if _preview_spell != null: return
	if spell == CastInputPanel.Spell.ATTACK_AREA:
		var burst := _setup_area_burst()
		burst.manifest()
		_preview_spell = burst
		return
	if spell == CastInputPanel.Spell.ATTACK_TARGET:
		player.aim_active = true
		var projectile := _setup_projectile()
		_place_projectile(projectile)
		projectile.manifest()
		_preview_spell = projectile
		return


func _on_spell_reset() -> void:
	player.aim_active = false
	magic_circle.clear_sequence()
	_dismiss_preview_spell()


func _on_spell_casted(spell: CastInputPanel.Spell) -> void:
	if spell == CastInputPanel.Spell.ATTACK_AREA:
		var burst := _take_preview_spell() as SpellAreaBurst
		if burst == null:
			burst = _setup_area_burst()
		burst.global_position = player.global_position
		burst.release(SPELL_AREA_DAMAGE)
		return
	if spell == CastInputPanel.Spell.ATTACK_TARGET:
		var projectile := _take_preview_spell() as SpellProjectile
		if projectile == null:
			projectile = _setup_projectile()
		_place_projectile(projectile)
		projectile.launch(Vector2.from_angle(player.aim_angle), SPELL_PROJECTILE_SPEED)
		return


func _on_basic_attack_requested(direction: Vector2) -> void:
	var projectile := basic_projectile_scene.instantiate() as SpellProjectile
	add_child(projectile)
	projectile.global_position = _spawn_origin()
	projectile.launch(direction, BASIC_ATTACK_SPEED)


func _on_enemy_new_died(enemy: Node) -> void:
	enemy.queue_free()


func _on_spell_sequence_changed(sequence: Array[StringName]) -> void:
	magic_circle.set_sequence(sequence)


func _on_cast_mode_changed(active: bool) -> void:
	magic_circle.visible = active
