class_name TutorialDim
extends ColorRect


const Z := 100
const ALPHA := 0.85
const FADE := 0.25
const EXTENT := 16384.0


var _raised: Dictionary[Node2D, Array] = {}
var _dismissed := false


func _ready() -> void:
	color = Color(0, 0, 0, 0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_as_relative = false
	z_index = Z
	position = -Vector2.ONE * EXTENT / 2.0
	size = Vector2.ONE * EXTENT
	var unshaded := CanvasItemMaterial.new()
	unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = unshaded
	create_tween().tween_property(self, "color:a", ALPHA, FADE)


func raise(nodes: Array[Node2D]) -> void:
	for node in nodes:
		if not is_instance_valid(node) or node in _raised: continue
		_raised[node] = [node.z_as_relative, node.z_index]
		node.z_as_relative = false
		node.z_index = Z + 1


func dismiss() -> void:
	if _dismissed: return
	_dismissed = true
	var tween := create_tween()
	tween.tween_property(self, "color:a", 0.0, FADE)
	tween.finished.connect(_restore)


func _restore() -> void:
	for node in _raised:
		if not is_instance_valid(node): continue
		node.z_as_relative = _raised[node][0]
		node.z_index = _raised[node][1]
	queue_free()
