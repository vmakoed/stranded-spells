class_name Slime
extends CharacterBody2D


@export var speed := 20.0
@export var direction := 1


func _ready() -> void:
	%ShieldBubble.radius = ($HurtboxComponent/CollisionShape2D.shape as CircleShape2D).radius
	%ShieldComponent.activate()
	%Sprite2D.flip_h = direction < 0


func _physics_process(_delta: float) -> void:
	velocity = Vector2(direction * speed, 0.0)
	move_and_slide()
	if is_on_wall():
		direction = -direction
		%Sprite2D.flip_h = direction < 0
