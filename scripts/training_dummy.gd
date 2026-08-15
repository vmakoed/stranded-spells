extends StaticBody2D


@onready var health_component: HealthComponent = %HealthComponent


func take_damage(value: float) -> void:
	print("damaged")
	health_component.damage(value)
