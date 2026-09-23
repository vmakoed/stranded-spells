class_name MagicMissileOrbit
extends Node2D


const FRONT_RADIUS = 16.0
const BACK_RADIUS = 10.0
const BACK_ANGLE = deg_to_rad(140.0)
const SLIDE_DURATION = CastInputPanel.CHARGE_COOLDOWN


var player: Player
var orbs: Array[SpellProjectile] = []
var _from_offsets: Array[float] = []
var _from_radii: Array[float] = []
var _slide_elapsed := SLIDE_DURATION


func add_orb(orb: SpellProjectile) -> void:
	var slot := orbs.size()
	orbs.append(orb)
	_from_offsets.append(_slot_offset(slot))
	_from_radii.append(_slot_radius(slot))
	_place(slot)


func _process(delta: float) -> void:
	if not is_instance_valid(player): return
	_slide_elapsed = minf(_slide_elapsed + delta, SLIDE_DURATION)
	for slot in orbs.size(): _place(slot)


func launch_front(speed: float) -> void:
	if orbs.is_empty() or not is_instance_valid(player): return
	for slot in orbs.size():
		_from_offsets[slot] = _current_offset(slot)
		_from_radii[slot] = _current_radius(slot)
	var orb: SpellProjectile = orbs.pop_front()
	_from_offsets.pop_front()
	_from_radii.pop_front()
	_slide_elapsed = 0.0
	if not is_instance_valid(orb): return
	orb.global_position = player.global_position + Vector2(FRONT_RADIUS, 0.0).rotated(player.aim_angle)
	orb.launch(Vector2.from_angle(player.aim_angle), speed)


func dismiss() -> void:
	for orb in orbs:
		if is_instance_valid(orb): orb.dismiss()
	orbs.clear()
	queue_free()


func _slide_weight() -> float:
	return ease(_slide_elapsed / SLIDE_DURATION, -2.0)


func _current_offset(slot: int) -> float:
	return lerp_angle(_from_offsets[slot], _slot_offset(slot), _slide_weight())


func _current_radius(slot: int) -> float:
	return lerpf(_from_radii[slot], _slot_radius(slot), _slide_weight())


func _slot_offset(slot: int) -> float:
	match slot:
		0: return 0.0
		1: return BACK_ANGLE
		_: return -BACK_ANGLE


func _slot_radius(slot: int) -> float:
	return FRONT_RADIUS if slot == 0 else BACK_RADIUS


func _place(slot: int) -> void:
	var orb := orbs[slot]
	if not is_instance_valid(orb): return
	var angle := player.aim_angle + _current_offset(slot)
	orb.global_position = player.global_position + Vector2(_current_radius(slot), 0.0).rotated(angle)
	orb.rotation = angle
