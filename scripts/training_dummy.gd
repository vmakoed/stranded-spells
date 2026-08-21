extends StaticBody2D


@onready var health_component: HealthComponent = %HealthComponent


func take_damage(value: float) -> void:
	print("damaged")
	health_component.damage(value)


func _on_health_component_health_below_minimum() -> void:
	await get_tree().create_timer(1.0).timeout
	health_component.reset()
