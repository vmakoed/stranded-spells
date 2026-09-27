class_name TimerRing
extends Node2D


const RADIUS := 4.0
const WIDTH := 2.0
const OFFSET := Vector2(0, -13)
const TRACK_COLOR := Color(0.12, 0.05, 0.18, 0.7)
const FILL_COLOR := Color(1, 0.85, 0.5)


var timer: Timer


func _ready() -> void:
	position = OFFSET
	z_index = 3
	var unshaded := CanvasItemMaterial.new()
	unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = unshaded


func _process(_delta: float) -> void:
	visible = is_instance_valid(timer) and not timer.is_stopped()
	if visible: queue_redraw()


func _draw() -> void:
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 16, TRACK_COLOR, WIDTH, false)
	var fraction := timer.time_left / timer.wait_time
	if fraction <= 0.0: return
	var start := -PI / 2
	draw_arc(Vector2.ZERO, RADIUS, start, start + TAU * fraction, 16, FILL_COLOR, WIDTH, false)
