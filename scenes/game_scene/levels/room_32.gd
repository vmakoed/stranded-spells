extends Room


func _ready_active_level() -> void:
	super()
	door_up.open()
	door_right.open()
	door_down.open()
