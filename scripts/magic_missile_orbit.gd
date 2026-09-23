class_name MagicMissileOrbit
extends Node2D


const FRONT_RADIUS = 16.0
const BACK_RADIUS = 10.0
const BACK_ANGLE = deg_to_rad(140.0)
const FOLLOW_SPEED = 18.0


var player: Player
var orbs: Array[SpellProjectile] = []
var _angles: Array[float] = []
var _radii: Array[float] = []


func add_orb(orb: SpellProjectile) -> void:
	var slot := orbs.size()
	orbs.append(orb)
	_angles.append(_slot_angle(slot))
	_radii.append(_slot_radius(slot))
	_place(slot)


func _process(delta: float) -> void:
	if not is_instance_valid(player): return
	var weight := 1.0 - exp(-FOLLOW_SPEED * delta)
	for slot in orbs.size():
		_angles[slot] = lerp_angle(_angles[slot], _slot_angle(slot), weight)
		_radii[slot] = lerpf(_radii[slot], _slot_radius(slot), weight)
		_place(slot)


func launch_front(speed: float) -> void:
	if orbs.is_empty() or not is_instance_valid(player): return
	var orb: SpellProjectile = orbs.pop_front()
	_angles.pop_front()
	_radii.pop_front()
	if not is_instance_valid(orb): return
	orb.global_position = player.global_position + Vector2(FRONT_RADIUS, 0.0).rotated(player.aim_angle)
	orb.launch(Vector2.from_angle(player.aim_angle), speed)


func dismiss() -> void:
	for orb in orbs:
		if is_instance_valid(orb): orb.dismiss()
	orbs.clear()
	queue_free()


func _slot_angle(slot: int) -> float:
	var aim := player.aim_angle
	match slot:
		0: return aim
		1: return aim + BACK_ANGLE
		_: return aim - BACK_ANGLE


func _slot_radius(slot: int) -> float:
	return FRONT_RADIUS if slot == 0 else BACK_RADIUS


func _place(slot: int) -> void:
	var orb := orbs[slot]
	if not is_instance_valid(orb): return
	orb.global_position = player.global_position + Vector2(_radii[slot], 0.0).rotated(_angles[slot])
	orb.rotation = _angles[slot]
