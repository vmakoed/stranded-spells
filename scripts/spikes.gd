@tool
class_name Spikes
extends Area2D


@export var raised := false:
	set(value):
		raised = value
		_snap()

@export var damage := 125.0


@onready var _sprite: AnimatedSprite2D = %AnimatedSprite2D


func _ready() -> void:
	_snap()
	if Engine.is_editor_hint(): return
	collision_layer = 0
	collision_mask = 8
	monitoring = raised
	area_entered.connect(_on_area_entered)


func raise() -> void:
	if raised: return
	raised = true
	set_deferred("monitoring", true)
	_play(&"turn_on")


func lower() -> void:
	if not raised: return
	raised = false
	set_deferred("monitoring", false)
	_play(&"turn_off")


func _play(anim: StringName) -> void:
	_sprite.play(anim)
	_sprite.set_frame_and_progress(0, 0.0)


func _snap() -> void:
	if not is_node_ready(): return
	var anim := &"turn_on" if raised else &"turn_off"
	_sprite.animation = anim
	_sprite.frame = _sprite.sprite_frames.get_frame_count(anim) - 1


func _on_area_entered(area: Area2D) -> void:
	if area is HurtboxComponent and area.get_parent() is EnemyNew:
		area.damage(damage, true)
