extends Node


signal level_won(level_path : String)


@onready var boxes: Node = %Boxes
@onready var door: Door = %Door


var boxes_count : int


func _ready() -> void:
	boxes_count = boxes.get_child_count()

	for box: Box in boxes.get_children():
		box.destroyed.connect(_on_box_destroyed)


func _on_box_destroyed() -> void:
	boxes_count -= 1

	if boxes_count == 0:
		door.open()


func _on_win_area_body_entered(body: Node2D) -> void:
	if body is Player:
		level_won.emit()
