class_name TreasureChest
extends Area2D


signal opened
signal travel_requested(path: String)


const FLASH_TIME = 0.5


@export var spell: CastInputPanel.Spell
@export var icon: Texture2D
@export var open_texture: Texture2D = preload("res://assets/textures/chest_open_4.png")
@export var save_id := ""
@export_file("*.tscn") var spell_room_path := ""

var is_open := false
var _traveling := false

@onready var sprite: Sprite2D = $Sprite2D
@onready var flash: ChestFlash = %Flash


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_on_body_entered)
	if GameState.get_flag(self, false): _set_open()


func _on_body_entered(body: Node2D) -> void:
	if body is not Player or _traveling: return
	if is_open:
		_travel(body)
		return
	GameState.set_flag(self, true)
	_set_open()
	if not spell_room_path:
		body.learn_spell(spell)
		body.play_pickup_sound()
		_show_icon()
	opened.emit()
	_travel(body)


func _travel(player: Player) -> void:
	if not spell_room_path: return
	_traveling = true
	player.velocity = Vector2.ZERO
	player.set_physics_process(false)
	await flash.burst(FLASH_TIME).finished
	GameState.set_checkpoint_level_entry_direction(GameState.EntryDirection.CENTER)
	travel_requested.emit(spell_room_path)


func _set_open() -> void:
	is_open = true
	sprite.texture = open_texture
	if not spell_room_path: set_deferred("monitoring", false)


func _show_icon() -> void:
	if not icon: return
	var icon_sprite := Sprite2D.new()
	icon_sprite.texture = icon
	icon_sprite.position = Vector2(0, -8)
	icon_sprite.z_index = 3
	add_child(icon_sprite)
	var tween := icon_sprite.create_tween()
	tween.tween_property(icon_sprite, "position:y", -20.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(icon_sprite, "modulate:a", 0.0, 0.4)
	tween.tween_callback(icon_sprite.queue_free)
