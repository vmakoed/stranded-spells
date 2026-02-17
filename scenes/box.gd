class_name Box
extends AnimatableBody2D


@onready var sprite: Sprite2D = %Sprite2D


func receive_push(direction: Vector2) -> void:
	var push_distance = 75.0
	var position_vector = direction * push_distance
	var tween = create_tween()

	tween \
		.tween_property(
			self, 
			"global_position",
			position_vector, 
			0.25
		).as_relative() \
		.from_current() \
		.set_trans(Tween.TRANS_CUBIC) \
		.set_ease(Tween.EASE_OUT)

	tween \
		.parallel() \
		.tween_property(
			sprite, 
			"modulate", 
			Color(1, 1, 1, 0),
			0.5
		).from_current() \
		.set_trans(Tween.TRANS_CUBIC) \
		.set_ease(Tween.EASE_IN)
		
	tween.tween_callback(queue_free)
