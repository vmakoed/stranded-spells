class_name TreasureChest
extends Area2D


@export var item: Player.Item
@export var icon: Texture2D
@export var open_texture: Texture2D = preload("res://assets/textures/chest_open_4.png")
@export var save_id := ""

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	if GameState.get_flag(self, false):
		_set_open()
		return
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is not Player: return
	body.collect(item)
	GameState.set_flag(self, true)
	body.play_pickup_sound()
	_set_open()
	_show_icon()


func _set_open() -> void:
	sprite.texture = open_texture
	set_deferred("monitoring", false)


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
