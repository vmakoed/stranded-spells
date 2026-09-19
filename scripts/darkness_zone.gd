class_name DarknessZone
extends Area2D


const HOLD_TIME := 0.2
const FADE_OUT_TIME := 0.2
const RECOVER_RATE := 2.0

@export var torches: Array[Torch] = []
@export var return_point: Marker2D
@export var grace_time := 2.5
@export var light_radius := 48.0

var _player: Player
var _dark_time := 0.0
var _teleporting := false
var _dispelled := false
var _fade: ScreenFade


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_build_fade()
	for torch in torches:
		if is_instance_valid(torch): torch.ignited.connect(_check_dispel)
	set_physics_process(false)
	_check_dispel()


func _physics_process(delta: float) -> void:
	if _teleporting: return
	var in_dark := is_instance_valid(_player) and not _near_lit_torch(_player.global_position)
	var step := delta if in_dark else -delta * RECOVER_RATE
	_dark_time = clampf(_dark_time + step, 0.0, grace_time)
	_fade.alpha = _dark_time / grace_time
	if _dark_time >= grace_time:
		_teleport()
		return
	if _player == null and _dark_time == 0.0:
		set_physics_process(false)
		if _dispelled: queue_free()


func _build_fade() -> void:
	_fade = ScreenFade.new()
	add_child(_fade)


func _near_lit_torch(pos: Vector2) -> bool:
	var radius_sq := light_radius * light_radius
	for torch: Torch in get_tree().get_nodes_in_group("torches"):
		if not torch.lit: continue
		if pos.distance_squared_to(torch.global_position) <= radius_sq: return true
	return false


func _teleport() -> void:
	_teleporting = true
	set_physics_process(false)
	var player := _player
	if is_instance_valid(player) and return_point:
		player.set_physics_process(false)
		player.global_position = return_point.global_position
	await get_tree().create_timer(HOLD_TIME).timeout
	if is_instance_valid(player): player.set_physics_process(true)
	await _fade.fade_to(0.0, FADE_OUT_TIME).finished
	_dark_time = 0.0
	_teleporting = false
	if _dispelled:
		queue_free()
		return
	set_physics_process(_player != null)


func _check_dispel() -> void:
	if torches.is_empty(): return
	for torch in torches:
		if is_instance_valid(torch) and not torch.lit: return
	_dispelled = true
	set_deferred("monitoring", false)
	if _teleporting: return
	if _dark_time > 0.0:
		_player = null
		set_physics_process(true)
		return
	queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body is not Player or _dispelled: return
	_player = body
	set_physics_process(true)


func _on_body_exited(body: Node2D) -> void:
	if body == _player: _player = null
