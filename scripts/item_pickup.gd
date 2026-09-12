class_name ItemPickup
extends Area2D
## World pickup that adds [member item] to the [Player]'s inventory on touch.
## Attach to an [Area2D] with a [CollisionShape2D]; the sprite is up to the scene.
## When [member shield_component] is set, the pickup is inert until the shield breaks.


@export var item: Player.Item
@export var shield_component: ShieldComponent


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1	# player
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is not Player: return
	if shield_component and shield_component.active: return
	body.collect(item)
	body.play_pickup_sound()
	queue_free()
