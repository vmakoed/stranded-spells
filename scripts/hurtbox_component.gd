class_name HurtboxComponent
extends Area2D

@export var health_component: HealthComponent
@export var shield_component: ShieldComponent

func damage(value: float, breaks_shield := false):
	if shield_component and shield_component.try_absorb(value, breaks_shield):
		return
	health_component.damage(value)
