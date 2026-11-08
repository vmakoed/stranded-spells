class_name Slime
extends CharacterBody2D


enum Axis { HORIZONTAL, VERTICAL, NONE }

@export var speed := 20.0
@export var direction := 1
@export var axis := Axis.HORIZONTAL
@export_range(0, 270, 90) var deflect_angle := 0


func _ready() -> void:
	%ShieldBubble.radius = ($HurtboxComponent/CollisionShape2D.shape as CircleShape2D).radius
	%ShieldComponent.activate()
	_update_facing()


func _physics_process(_delta: float) -> void:
	%ShieldComponent.direction = Vector2.from_angle(global_rotation + deg_to_rad(deflect_angle))
	if axis == Axis.NONE:
		return
	var move_axis := Vector2.DOWN if axis == Axis.VERTICAL else Vector2.RIGHT
	velocity = move_axis * direction * speed
	move_and_slide()
	if is_on_wall():
		direction = -direction
		_update_facing()


func _update_facing() -> void:
	if axis == Axis.HORIZONTAL:
		%Sprite2D.flip_h = direction < 0
