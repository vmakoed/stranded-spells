extends Node


signal focus_on_target_requested
signal blur_on_target_requested
signal focus_on_next_target_requested
signal focus_on_previous_target_requested


const FLICK_THRESHOLD := 0.6
const RESET_THRESHOLD := 0.3

var _flick_armed := true


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"focus_target"):
		focus_on_target_requested.emit()
		return

	if event.is_action_released(&"focus_target"):
		blur_on_target_requested.emit()
		return

	if event.is_action_pressed(&"reset_cast"):
		SpellSystem.clear_spell_sequence()
		return
		
	var focus_direction := Input.get_vector(&"focus_target_left", &"focus_target_right", &"focus_target_up", &"focus_target_down")
	var strength := focus_direction.length()

	if _flick_armed and strength > FLICK_THRESHOLD:
		_flick_armed = false

		var dominant := focus_direction.x if absf(focus_direction.x) >= absf(focus_direction.y) else focus_direction.y
		if dominant > 0.0:
			focus_on_next_target_requested.emit()
		else:
			focus_on_previous_target_requested.emit()
	elif not _flick_armed and strength < RESET_THRESHOLD:
		_flick_armed = true
