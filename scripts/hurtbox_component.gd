class_name HurtboxComponent
extends Area2D

@export var health_component: HealthComponent
@export var shield_component: ShieldComponent
@export var stun_component: StunComponent

func damage(value: float, stun := 0.0) -> bool:
	if shield_component and shield_component.try_absorb(value):
		return true
	if health_component: health_component.damage(value)
	if stun_component: stun_component.stun_damage(stun)
	return false
