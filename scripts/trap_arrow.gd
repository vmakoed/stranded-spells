class_name TrapArrow
extends Area2D


const WORLD_LAYER = 3


@export var damage := 1.0


var velocity := Vector2.ZERO
var _push := Vector2.ZERO


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position += velocity * delta


func launch(direction: Vector2, speed: float, push: float) -> void:
	velocity = direction.normalized() * speed
	_push = direction.normalized() * push
	rotation = direction.angle() - PI / 2.0


func _hit() -> void:
	velocity = Vector2.ZERO
	set_deferred(&"monitoring", false)
	queue_free()


func _is_world(body: Node2D) -> bool:
	if body is TileMapLayer: return true
	if body is PhysicsBody2D: return body.get_collision_layer_value(WORLD_LAYER)
	return false


func _on_area_entered(area: Area2D) -> void:
	if not area is HurtboxComponent: return
	var player := area.get_parent() as Player
	if player:
		(area as HurtboxComponent).damage(damage)
		player.knock_back(_push)
	_hit()


func _on_body_entered(body: Node2D) -> void:
	if _is_world(body): _hit()
