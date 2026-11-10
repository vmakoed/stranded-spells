class_name AimAssist
extends RefCounted


const RANGE = 170.0
const CONE = deg_to_rad(35.0)
const DISTANCE_WEIGHT = 0.5
const WORLD_MASK = 1 << 2
const GROUP = &"aim_targets"


static func find_target(origin: Vector2, direction: Vector2, space: PhysicsDirectSpaceState2D) -> Node2D:
	var best: Node2D = null
	var best_score := INF
	for node in _candidates():
		var target := _aim_node(node)
		if target == null: continue
		var offset := target.global_position - origin
		var distance := offset.length()
		if distance > RANGE or distance < 0.01: continue
		var angle := absf(direction.angle_to(offset))
		if angle > CONE: continue
		var score := angle / CONE + DISTANCE_WEIGHT * distance / RANGE
		if score >= best_score: continue
		if not _has_line_of_sight(origin, target, node, space): continue
		best = target
		best_score = score
	return best


static func is_valid(target: Node2D) -> bool:
	if not is_instance_valid(target): return false
	if target is Switch: return not (target as Switch).on
	var parent := target.get_parent()
	if parent is EnemyNew: return not (parent as EnemyNew).is_dead()
	if parent is BreakableBox: return not (parent as BreakableBox).is_broken()
	return false


static func _candidates() -> Array[Node]:
	return (Engine.get_main_loop() as SceneTree).get_nodes_in_group(GROUP)


static func _aim_node(node: Node) -> Node2D:
	if node is EnemyNew:
		var enemy := node as EnemyNew
		return null if enemy.is_dead() else enemy.hurtbox()
	if node is BreakableBox:
		var box := node as BreakableBox
		return null if box.is_broken() else box.hurtbox
	if node is Switch:
		var switch := node as Switch
		return null if switch.on else switch
	return null


static func _has_line_of_sight(origin: Vector2, target: Node2D, node: Node, space: PhysicsDirectSpaceState2D) -> bool:
	var query := PhysicsRayQueryParameters2D.create(origin, target.global_position, WORLD_MASK)
	var hit := space.intersect_ray(query)
	return hit.is_empty() or hit.collider == node
