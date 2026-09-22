class_name TorchSpark
extends Node2D

signal arrived

const POP_DURATION := 0.1

@onready var visual: Node2D = %Visual
@onready var trail: CPUParticles2D = %Trail


func fly(target: Vector2, delay: float, speed: float) -> void:
	var start := global_position
	var duration := start.distance_to(target) / speed
	rotation = start.angle_to_point(target)
	visual.scale = Vector2.ZERO
	var tween := create_tween()
	tween.tween_interval(delay)
	tween.tween_callback(func() -> void: trail.emitting = true)
	tween.parallel().tween_property(visual, "scale", Vector2.ONE, POP_DURATION)
	tween.tween_property(self, "global_position", target, duration) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_IN)
	tween.tween_callback(_land)


func _land() -> void:
	arrived.emit()
	visual.hide()
	trail.emitting = false
	await get_tree().create_timer(trail.lifetime + 0.1).timeout
	if is_inside_tree(): queue_free()
