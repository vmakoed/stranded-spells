class_name ChestFlash
extends Node2D


const FILL_RADIUS = 400.0


var radius := 0.0:
	set(value):
		radius = value
		queue_redraw()


func _draw() -> void:
	if radius > 0.0: draw_circle(Vector2.ZERO, radius, Color.WHITE)


func burst(duration: float) -> Tween:
	radius = 0.0
	show()
	var tween := create_tween()
	tween.tween_property(self, "radius", FILL_RADIUS, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	return tween
