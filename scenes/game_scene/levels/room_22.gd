extends Room


func _ready_active_level() -> void:
	super()
	door_down.open()


func _on_win_area_body_entered(body: Node2D) -> void:
	if body is Player: level_won.emit()
