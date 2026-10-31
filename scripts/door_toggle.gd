class_name DoorToggle
extends Node2D


@export var plates: Array[PressurePlate] = []
@export var doors: Array[ChallengeDoor] = []
@export var wires: Array[TileMapLayer] = []
@export var save_id := ""


var _latched := -1
var _open := false


func _ready() -> void:
	doors.assign(doors.filter(is_instance_valid))
	var state: Array = GameState.get_flag(self, [-1, false])
	_latched = state[0]
	_open = state[1]
	for door in doors: door.closed = not _open
	_light_wires()
	for i in plates.size():
		if is_instance_valid(plates[i]): plates[i].pressed.connect(_on_pressed.bind(i))


func _on_pressed(index: int) -> void:
	if index == _latched: return
	_latched = index
	_open = not _open
	for door in doors:
		if _open: door.open()
		else: door.close()
	_light_wires()
	GameState.set_flag(self, [_latched, _open])


func _light_wires() -> void:
	for i in wires.size():
		if is_instance_valid(wires[i]):
			wires[i].modulate = ProgressRing.FILL_COLOR if i == _latched else Color.WHITE
