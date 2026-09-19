class_name ScreenFade
extends CanvasLayer


var alpha: float:
	get: return _rect.color.a
	set(value): _rect.color.a = value


var _rect: ColorRect


func _init() -> void:
	layer = 10
	_rect = ColorRect.new()
	_rect.color = Color(0, 0, 0, 0)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_rect)


func fade_to(target: float, duration: float) -> Tween:
	var tween := create_tween()
	tween.tween_property(self, "alpha", target, duration)
	return tween
