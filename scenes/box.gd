class_name Box
extends AnimatableBody2D


signal destroyed


const PUSH_DISTANCE = 20.0


@onready var sprite: Sprite2D = %Sprite2D


func receive_push(direction: Vector2) -> void:
	var position_vector = direction * PUSH_DISTANCE
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
		
	destroyed.emit()
	tween.tween_callback(queue_free)
