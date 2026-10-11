extends Node


signal level_lost
signal level_won(level_path: String)



@export_file("*.tscn") var exit_up_path: String
@export_file("*.tscn") var exit_left_path: String
@export_file("*.tscn") var exit_down_path: String
@export_file("*.tscn") var exit_right_path: String


const SPELL_AREA_DAMAGE = 50.0
const SPELL_HEAL_AMOUNT = 1.0
const SPELL_PROJECTILE_SPEED = 160.0
const SPELL_PROJECTILE_OFFSET = 16.0
const MAGIC_MISSILE_SPEED = 220.0
const SPELL_MISTY_STEP_DISTANCE = 48.0
const AIMED_SPELLS: Array[CastInputPanel.Spell] = [
	CastInputPanel.Spell.ATTACK_TARGET,
	CastInputPanel.Spell.MAGIC_MISSILE,
	CastInputPanel.Spell.MISTY_STEP,
]


@export var projectile_scene := preload("res://scenes/spell_projectile_area.tscn")
@export var area_burst_scene := preload("res://scenes/spell_area_burst.tscn")
@export var heal_scene := preload("res://scenes/spell_heal.tscn")
@export var shield_scene := preload("res://scenes/spell_shield.tscn")
@export var basic_projectile_scene := preload("res://scenes/basic_attack_projectile.tscn")
@export var misty_step_scene := preload("res://scenes/spell_misty_step.tscn")


@onready var player: Player = %PlayerCharacter
@onready var magic_circle: MagicCircle = %MagicCircleNode


var _preview_spells: Array[Node2D] = [null, null]
var _slot_spells: Array = [null, null]
var level_state: LevelState

var player_spawn_up_marker: Marker2D
var player_spawn_right_marker: Marker2D
var player_spawn_down_marker: Marker2D
var player_spawn_left_marker: Marker2D


func _ready() -> void:
	player.destroyed.connect(func():
		_dismiss_preview_spells()
		level_lost.emit()
	)
	player.fainted.connect(_dismiss_preview_spells)
	GameUIBridge.spell_equipped.connect(_on_spell_equipped)
	GameUIBridge.spell_reset.connect(_on_spell_reset)
	GameUIBridge.spell_casted.connect(_on_spell_casted)
	GameUIBridge.spell_sequence_changed.connect(_on_spell_sequence_changed)
	GameUIBridge.cast_mode_changed.connect(_on_cast_mode_changed)

	_initialize_markers()
	_position_player()
	GameUIBridge.level_ready.emit()


func _process(_delta: float) -> void:
	for slot in _preview_spells.size():
		var preview := _preview_spells[slot]
		if preview == null: continue
		if not is_instance_valid(player) or not is_instance_valid(preview):
			_preview_spells[slot] = null
			continue
		_place_preview(preview)


func _initialize_markers() -> void:
	player_spawn_up_marker = get_node_or_null("%PlayerSpawnUpMarker")
	player_spawn_right_marker = get_node_or_null("%PlayerSpawnRightMarker")
	player_spawn_down_marker = get_node_or_null("%PlayerSpawnDownMarker")
	player_spawn_left_marker = get_node_or_null("%PlayerSpawnLeftMarker")


func _position_player() -> void:
	if (GameState.get_checkpoint_level_entry_direction() == GameState.EntryDirection.NONE):
		return

	if player_spawn_up_marker and (GameState.get_checkpoint_level_entry_direction() == GameState.EntryDirection.UP):
		player.global_position = player_spawn_up_marker.global_position

	if player_spawn_right_marker and (GameState.get_checkpoint_level_entry_direction() == GameState.EntryDirection.RIGHT):
		player.global_position = player_spawn_right_marker.global_position

	if player_spawn_down_marker and (GameState.get_checkpoint_level_entry_direction() == GameState.EntryDirection.DOWN):
		player.global_position = player_spawn_down_marker.global_position

	if player_spawn_left_marker and (GameState.get_checkpoint_level_entry_direction() == GameState.EntryDirection.LEFT):
		player.global_position = player_spawn_left_marker.global_position


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(player): return
	for preview in _preview_spells:
		if preview is SpellMistyStep and is_instance_valid(preview):
			preview.global_position = player.blink_destination(SPELL_MISTY_STEP_DISTANCE)


func _place_preview(preview: Node2D) -> void:
	if preview is SpellProjectile:
		_place_projectile(preview)
	elif preview is SpellMistyStep:
		return
	else:
		preview.global_position = player.global_position


func _setup_projectile() -> SpellProjectile:
	var projectile := projectile_scene.instantiate() as SpellProjectile
	add_child(projectile)
	return projectile


func _setup_area_burst() -> SpellAreaBurst:
	var burst := area_burst_scene.instantiate() as SpellAreaBurst
	add_child(burst)
	burst.global_position = player.global_position
	return burst


func _setup_heal() -> SpellHeal:
	var heal := heal_scene.instantiate() as SpellHeal
	add_child(heal)
	heal.target = player
	heal.global_position = player.global_position
	heal.arrived.connect(_on_heal_arrived)
	return heal


func _setup_shield() -> SpellHeal:
	var shield := shield_scene.instantiate() as SpellHeal
	add_child(shield)
	shield.target = player
	shield.global_position = player.global_position
	shield.arrived.connect(_on_shield_arrived)
	return shield


func _setup_magic_missiles() -> MagicMissileOrbit:
	var orbit := MagicMissileOrbit.new()
	orbit.player = player
	add_child(orbit)
	for i in MagicMissileOrbit.ORB_COUNT:
		var orb := basic_projectile_scene.instantiate() as SpellProjectile
		add_child(orb)
		orbit.add_orb(orb)
		orb.manifest()
	return orbit


func _setup_misty_step() -> SpellMistyStep:
	var step := misty_step_scene.instantiate() as SpellMistyStep
	add_child(step)
	step.global_position = player.global_position
	return step


func _spawn_origin() -> Vector2:
	return player.global_position + \
		Vector2(SPELL_PROJECTILE_OFFSET, 0.0).rotated(player.aim_angle)


func _place_projectile(projectile: SpellProjectile) -> void:
	projectile.global_position = _spawn_origin()
	projectile.rotation = player.aim_angle


func _dismiss_preview_spells() -> void:
	for slot in _preview_spells.size(): _dismiss_preview_spell(slot)


func _dismiss_preview_spell(slot: int) -> void:
	var preview := _preview_spells[slot]
	_preview_spells[slot] = null
	if preview != null and is_instance_valid(preview): preview.dismiss()


func _take_preview_spell(slot: int) -> Node2D:
	var spell := _preview_spells[slot]
	_preview_spells[slot] = null
	if spell != null and not is_instance_valid(spell): return null
	return spell


func _refresh_aim() -> void:
	player.aim_active = _slot_spells.any(func(spell): return spell != null and spell in AIMED_SPELLS)


func _on_spell_equipped(slot: int, spell: CastInputPanel.Spell) -> void:
	_dismiss_preview_spell(slot)
	_slot_spells[slot] = spell
	_refresh_aim()
	if spell == CastInputPanel.Spell.ATTACK_AREA:
		var burst := _setup_area_burst()
		burst.manifest()
		_preview_spells[slot] = burst
	elif spell == CastInputPanel.Spell.ATTACK_TARGET:
		var projectile := _setup_projectile()
		_place_projectile(projectile)
		projectile.manifest()
		_preview_spells[slot] = projectile
	elif spell == CastInputPanel.Spell.HEAL:
		var heal := _setup_heal()
		heal.manifest()
		_preview_spells[slot] = heal
	elif spell == CastInputPanel.Spell.SHIELD:
		var shield := _setup_shield()
		shield.manifest()
		_preview_spells[slot] = shield
	elif spell == CastInputPanel.Spell.MAGIC_MISSILE:
		_preview_spells[slot] = _setup_magic_missiles()
	elif spell == CastInputPanel.Spell.MISTY_STEP:
		var step := _setup_misty_step()
		step.manifest()
		_preview_spells[slot] = step


func _on_spell_reset() -> void:
	_slot_spells = [null, null]
	_refresh_aim()
	magic_circle.clear_sequence()
	_dismiss_preview_spells()


func _on_spell_casted(slot: int, spell: CastInputPanel.Spell) -> void:
	if spell == CastInputPanel.Spell.ATTACK_AREA:
		var burst := _take_preview_spell(slot) as SpellAreaBurst
		if burst == null:
			burst = _setup_area_burst()
		burst.global_position = player.global_position
		burst.release(SPELL_AREA_DAMAGE)
		return
	if spell == CastInputPanel.Spell.ATTACK_TARGET:
		var projectile := _take_preview_spell(slot) as SpellProjectile
		if projectile == null:
			projectile = _setup_projectile()
		_place_projectile(projectile)
		projectile.launch(Vector2.from_angle(player.aim_angle), SPELL_PROJECTILE_SPEED)
		return
	if spell == CastInputPanel.Spell.HEAL:
		var heal := _take_preview_spell(slot) as SpellHeal
		if heal == null:
			heal = _setup_heal()
		heal.release()
		return
	if spell == CastInputPanel.Spell.SHIELD:
		var shield := _take_preview_spell(slot) as SpellHeal
		if shield == null:
			shield = _setup_shield()
		shield.release()
		return
	if spell == CastInputPanel.Spell.MISTY_STEP:
		var step := _take_preview_spell(slot) as SpellMistyStep
		if step == null:
			step = _setup_misty_step()
		var origin := player.global_position
		var destination := player.blink_destination(SPELL_MISTY_STEP_DISTANCE)
		player.teleport(destination)
		step.release(origin, destination)
		return
	if spell == CastInputPanel.Spell.MAGIC_MISSILE:
		var orbit := _take_preview_spell(slot) as MagicMissileOrbit
		if orbit == null: return
		orbit.launch_all(MAGIC_MISSILE_SPEED)
		return


func _on_heal_arrived() -> void:
	if not is_instance_valid(player): return
	player.heal(SPELL_HEAL_AMOUNT)


func _on_shield_arrived() -> void:
	if not is_instance_valid(player): return
	player.grant_shield()


func _on_spell_sequence_changed(sequence: Array[StringName]) -> void:
	magic_circle.set_sequence(sequence)


func _on_cast_mode_changed(active: bool, _slot: int) -> void:
	magic_circle.visible = active


func _on_enemy_detection_area_body_entered(body: Node2D) -> void:
	if body is not Player: return
	for node in get_tree().get_nodes_in_group("enemies"):
		if node is EnemyNew:
			node.player = player
			node.start_chase()


func _on_win_chest_body_entered(body: Node2D) -> void:
	if body is Player: 
		level_won.emit("res://scenes/game_scene/levels/room_prototype_1.tscn")


func _on_exit_up_area_body_entered(body: Node2D) -> void:
	if (body is Player) and exit_up_path:
		GameState.set_checkpoint_level_entry_direction(GameState.EntryDirection.DOWN)
		level_won.emit(exit_up_path)


func _on_exit_right_area_body_entered(body: Node2D) -> void:
	if (body is Player) and exit_right_path:
		GameState.set_checkpoint_level_entry_direction(GameState.EntryDirection.LEFT)
		level_won.emit(exit_right_path)


func _on_exit_down_area_body_entered(body: Node2D) -> void:
	if (body is Player) and exit_down_path:
		GameState.set_checkpoint_level_entry_direction(GameState.EntryDirection.UP)
		level_won.emit(exit_down_path)


func _on_exit_left_area_body_entered(body: Node2D) -> void:
	if (body is Player) and exit_left_path:
		GameState.set_checkpoint_level_entry_direction(GameState.EntryDirection.RIGHT)
		level_won.emit(exit_left_path)
