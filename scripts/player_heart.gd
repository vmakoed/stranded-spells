extends Control


var solid := true: set = _set_solid


func _ready() -> void:
	_update_texture()


func _update_texture() -> void:
	%SolidHeartTexture.visible = solid
	%HollowHeartTexture.visible = !solid


func _set_solid(new_value: bool) -> void:
	if new_value == solid: return

	solid = new_value
	_update_texture()
