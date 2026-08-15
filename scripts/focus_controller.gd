# TODO: refactor with FocusRegistry autoload pattern
extends Node


@export var focus_input: Node
@export var player: Player
@export var focus_sprite_template: Sprite2D


var focused_on_target := false
var focus_sprite: Sprite2D
var focus_node: Node2D


func _ready() -> void:
	focus_input.focus_on_target_requested.connect(_on_focus_on_target_requested)
	focus_input.blur_on_target_requested.connect(_on_blur_on_target_requested)
	focus_input.focus_on_next_target_requested.connect(_on_focus_on_next_target_requested)
	focus_input.focus_on_previous_target_requested.connect(_on_focus_on_previous_target_requested)


func get_focus_node() -> Node:
	if not focused_on_target: return player
	return focus_node


func _clear_focus() -> void:
	focused_on_target = false

	if is_instance_valid(focus_sprite): 
		focus_node.destroyed.disconnect(_on_focus_node_destroyed)
		focus_sprite.queue_free()
	
	focus_node = null
	player.focus()
	

func _focus_on(node: Node2D) -> void:
	player.unfocus()
	focus_sprite = focus_sprite_template.duplicate()
	focus_node = node
	focus_node.add_child(focus_sprite)
	focus_node.destroyed.connect(_on_focus_node_destroyed)
	focus_sprite.show()


func _get_focus_targets_ordered_by_distance() -> Array[Node]:
	var focus_targets = get_tree(). \
		get_nodes_in_group("enemies"). \
		filter(
			func(enemy: Node): return not enemy.dead
		)
	focus_targets.sort_custom(_sort_by_distance)
	return focus_targets


func _sort_by_distance(node_1: Node, node_2: Node) -> bool:
	var player_position = player.global_position

	return player_position.distance_to(node_1.global_position) < \
		player_position.distance_to(node_2.global_position)


func _on_focus_on_target_requested() -> void:
	_clear_focus()
	var focus_targets := _get_focus_targets_ordered_by_distance()
	if focus_targets.is_empty(): return
	_focus_on(focus_targets[0])
	focused_on_target = true


func _on_blur_on_target_requested() -> void:
	if not focused_on_target: return
	_clear_focus()


func _on_focus_on_next_target_requested() -> void:
	if not focused_on_target: return _clear_focus()
	var focus_targets := _get_focus_targets_ordered_by_distance()
	if focus_targets.is_empty(): return _clear_focus()
	var current_focus_index = focus_targets.find(focus_node)
	_clear_focus()
	var next_focus_index = current_focus_index + 1
	if (next_focus_index > focus_targets.size() - 1): next_focus_index = 0
	_focus_on(focus_targets[next_focus_index])
	focused_on_target = true


func _on_focus_on_previous_target_requested() -> void:
	if not focused_on_target: return
	var focus_targets := _get_focus_targets_ordered_by_distance()
	if focus_targets.is_empty(): return
	var current_focus_index = focus_targets.find(focus_node)
	_clear_focus()
	var next_focus_index = current_focus_index - 1
	if (next_focus_index < 0): next_focus_index = focus_targets.size() - 1
	_focus_on(focus_targets[next_focus_index])
	focused_on_target = true


func _on_focus_node_destroyed() -> void:
	_on_focus_on_next_target_requested()
