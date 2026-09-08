extends Area2D


@export var damage := 1.0

func _on_area_entered(area: Area2D) -> void:
	if area is HurtboxComponent: area.damage(damage)
