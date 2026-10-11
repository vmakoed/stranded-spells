class_name ProgressRing
extends Node2D


const TRACK_COLOR := Color(0.12, 0.05, 0.18, 0.7)
const FILL_COLOR := Color(1, 0.85, 0.5)
const OUTLINE_COLOR := Color(0.85, 0.8, 0.95, 0.3)
const OUTLINE_WIDTH := 1.0


var radius := 4.0
var width := 2.0
var value := 0.0:
	set(new_value):
		value = clampf(new_value, 0.0, 1.0)
		queue_redraw()


func _ready() -> void:
	z_index = 3
	var unshaded := CanvasItemMaterial.new()
	unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = unshaded


func _draw() -> void:
	var edge := (width + OUTLINE_WIDTH) / 2
	draw_arc(Vector2.ZERO, radius + edge, 0.0, TAU, 24, OUTLINE_COLOR, OUTLINE_WIDTH, false)
	draw_arc(Vector2.ZERO, radius - edge, 0.0, TAU, 16, OUTLINE_COLOR, OUTLINE_WIDTH, false)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 16, TRACK_COLOR, width, false)
	if value <= 0.0: return
	var start := -PI / 2
	draw_arc(Vector2.ZERO, radius, start, start + TAU * value, 16, FILL_COLOR, width, false)
