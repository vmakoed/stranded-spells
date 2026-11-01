class_name HurtboxComponent
extends Area2D

@export var health_component: HealthComponent
@export var shield_component: ShieldComponent

func damage(value: float) -> bool:
	if shield_component and shield_component.try_absorb(value):
		return true
	if health_component: health_component.damage(value)
	return false
