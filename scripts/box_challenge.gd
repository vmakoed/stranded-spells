class_name BoxChallenge
extends Challenge


const BOX_SCENE := preload("res://scenes/breakable_box.tscn")


@export var time_limit := 3.0


var _box: BreakableBox
var _index := 0
var _timer: Timer


func _ready() -> void:
	super()
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.timeout.connect(_reset)
	add_child(_timer)


func _start() -> void:
	for door in doors:
		if is_instance_valid(door): door.close()
	_spawn_box(0)
	started.emit()


func _spawn_box(index: int) -> void:
	_index = index
	var box := BOX_SCENE.instantiate() as BreakableBox
	box.shielded = shielded
	owner.add_child(box)
	box.global_position = spawn_points[index].global_position
	var ring := TimerRing.new()
	ring.timer = _timer
	box.add_child(ring)
	box.destroyed.connect(_on_box_destroyed.bind(box))
	_box = box


func _on_box_destroyed(box: BreakableBox) -> void:
	if box != _box: return
	_box = null
	_timer.stop()
	if _index == spawn_points.size() - 1:
		complete()
		return
	_spawn_box(_index + 1)
	_timer.start(time_limit)


func _reset() -> void:
	if is_instance_valid(_box): _box.queue_free()
	_box = null
	failed.emit()
	_spawn_box(0)
