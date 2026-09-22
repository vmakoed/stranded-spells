class_name BreakableBox
extends StaticBody2D


signal destroyed


const DEATH_SHATTER_SCENE = preload("res://scenes/game_scene/death_shatter.tscn")
const BREAK_FLASH_HOLD = 0.1


@export var shielded := false


@onready var sprite: Sprite2D = %Sprite2D
@onready var collision_shape: CollisionShape2D = %CollisionShape2D
@onready var hurtbox: HurtboxComponent = %HurtboxComponent
@onready var shield: ShieldComponent = %ShieldComponent
@onready var shield_bubble: ShieldBubble = %ShieldBubble


var _broken := false


func _ready() -> void:
	if shielded:
		shield.activate()


func _on_health_component_health_below_minimum() -> void:
	if _broken: return
	_broken = true

	collision_shape.set_deferred("disabled", true)
	hurtbox.set_deferred("monitorable", false)
	shield.disable()
	shield_bubble.disable()

	var flash_material: ShaderMaterial = sprite.material
	flash_material.set_shader_parameter("flash_amount", 1.0)
	await get_tree().create_timer(BREAK_FLASH_HOLD).timeout
	_shatter()


func _shatter() -> void:
	var shatter: DeathShatter = DEATH_SHATTER_SCENE.instantiate()
	shatter.z_index = z_index + 1
	get_parent().add_child(shatter)
	shatter.global_position = sprite.global_position
	shatter.play(sprite)

	destroyed.emit()
	queue_free()
