extends Room


@onready var boxes: Node = %Boxes


var boxes_count: int


func _ready_cleared_level() -> void:
	super()
	for box: Box in boxes.get_children(): box.queue_free()


func _ready_active_level() -> void:
	super()
	boxes_count = boxes.get_child_count()
	for box: Box in boxes.get_children(): box.destroyed.connect(_on_box_destroyed)


func _on_box_destroyed() -> void:
	boxes_count -= 1
	if boxes_count == 0: _clear_level()
