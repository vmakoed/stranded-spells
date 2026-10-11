class_name TimerRing
extends ProgressRing


const OFFSET := Vector2(0, -13)


var timer: Timer


func _ready() -> void:
	super()
	position = OFFSET


func _process(_delta: float) -> void:
	visible = is_instance_valid(timer) and not timer.is_stopped()
	if visible: value = timer.time_left / timer.wait_time
