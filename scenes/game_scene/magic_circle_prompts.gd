class_name MagicCirclePrompts
extends Control
## Shows, next to each MagicCircle marker, the spells that continue the current
## cast sequence with that marker's action. Lives in the screen-space UI and
## projects marker positions out of the level SubViewport every frame.


const HIGHLIGHT_COLOR = Color(0.5, 0.72, 0.78, 1.0)	# MagicCircle.ACTIVE_TINT
const OUTLINE_COLOR = Color(0.0, 0.0, 0.0, 0.8)
const FONT_SIZE = 28
const OUTLINE_SIZE = 4
const GAP_WORLD_PX = 10.0	# marker centre -> list edge, in SubViewport pixels (marker half-extent is 8)

const LABEL_ALIGNMENTS: Dictionary[CastInputPanel.SpellDirection, HorizontalAlignment] = {
	CastInputPanel.SpellDirection.UP: HORIZONTAL_ALIGNMENT_CENTER,
	CastInputPanel.SpellDirection.DOWN: HORIZONTAL_ALIGNMENT_CENTER,
	CastInputPanel.SpellDirection.LEFT: HORIZONTAL_ALIGNMENT_RIGHT,
	CastInputPanel.SpellDirection.RIGHT: HORIZONTAL_ALIGNMENT_LEFT
}


var sequence: Array[StringName] = []

var _circle: MagicCircle


@onready var lists: Dictionary[CastInputPanel.SpellDirection, VBoxContainer] = {
	CastInputPanel.SpellDirection.UP: %UpList,
	CastInputPanel.SpellDirection.RIGHT: %RightList,
	CastInputPanel.SpellDirection.DOWN: %DownList,
	CastInputPanel.SpellDirection.LEFT: %LeftList
}


func _ready() -> void:
	_build_label_pools()
	GameUIBridge.spell_sequence_changed.connect(_on_spell_sequence_changed)
	GameUIBridge.spell_reset.connect(_on_spell_reset)
	_rebuild()	# CastInputPanel's initial spell_reset fires before we connect


func _process(_delta: float) -> void:
	visible = _ensure_circle()
	if visible: _layout()


func _ensure_circle() -> bool:
	if is_instance_valid(_circle) and _circle.is_inside_tree(): return true
	_circle = get_tree().get_first_node_in_group(MagicCircle.GROUP_NAME) as MagicCircle
	return is_instance_valid(_circle) and _circle.is_inside_tree()


func _build_label_pools() -> void:
	for direction in lists:
		var list := lists[direction]
		for _index in CastInputPanel.Spell.size():
			var label := Label.new()
			label.visible = false
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			label.horizontal_alignment = LABEL_ALIGNMENTS[direction]
			label.add_theme_font_size_override(&"font_size", FONT_SIZE)
			label.add_theme_constant_override(&"outline_size", OUTLINE_SIZE)
			label.add_theme_color_override(&"font_outline_color", OUTLINE_COLOR)
			list.add_child(label)


func _rebuild() -> void:
	var complete_spell: Variant = CastInputPanel.find_complete_spell(sequence)

	for direction in lists:
		var action: StringName = CastInputPanel.SPELL_ACTIONS[direction]
		var spells := CastInputPanel.spells_for_next_action(sequence, action)
		if complete_spell != null and sequence.back() == action:
			spells.push_front(complete_spell)
		_fill_list(lists[direction], spells, complete_spell)

	if _ensure_circle(): _layout()


func _fill_list(list: VBoxContainer, spells: Array[CastInputPanel.Spell], complete_spell: Variant) -> void:
	var labels := list.get_children()
	for index in labels.size():
		var label: Label = labels[index]
		label.visible = index < spells.size()
		if not label.visible: continue

		label.text = CastInputPanel.SPELL_LABELS[spells[index]]
		if complete_spell != null and spells[index] == complete_spell:
			label.add_theme_color_override(&"font_color", HIGHLIGHT_COLOR)
		else:
			label.remove_theme_color_override(&"font_color")

	list.visible = not spells.is_empty()


func _layout() -> void:
	var sub_viewport := _circle.get_viewport() as SubViewport
	var container := sub_viewport.get_parent() as SubViewportContainer if sub_viewport else null
	if container == null:
		hide()
		return

	var viewport_scale := container.size / Vector2(sub_viewport.size)
	var gap := GAP_WORLD_PX * viewport_scale.x

	for direction in lists:
		var list := lists[direction]
		if not list.visible: continue

		var canvas_position := _circle.get_marker_canvas_position(CastInputPanel.SPELL_ACTIONS[direction])
		var anchor := _to_screen(canvas_position, container, sub_viewport, viewport_scale)
		list.reset_size()	# size := combined minimum size, synchronous
		list.position = (anchor + _list_offset(direction, list.size, gap)).round()


## Converts a SubViewport canvas position to this control's local coordinates.
func _to_screen(canvas_position: Vector2, container: SubViewportContainer, sub_viewport: SubViewport, viewport_scale: Vector2) -> Vector2:
	if sub_viewport.snap_2d_transforms_to_pixel:
		canvas_position = (canvas_position + Vector2(0.5, 0.5)).floor()	# match the renderer's sprite snapping
	return container.global_position - global_position + canvas_position * viewport_scale


func _list_offset(direction: CastInputPanel.SpellDirection, list_size: Vector2, gap: float) -> Vector2:
	match direction:
		CastInputPanel.SpellDirection.DOWN: return Vector2(-list_size.x * 0.5, gap)
		CastInputPanel.SpellDirection.UP: return Vector2(-list_size.x * 0.5, -gap - list_size.y)
		CastInputPanel.SpellDirection.RIGHT: return Vector2(gap, -list_size.y * 0.5)
		CastInputPanel.SpellDirection.LEFT: return Vector2(-gap - list_size.x, -list_size.y * 0.5)
	return Vector2.ZERO


func _on_spell_sequence_changed(new_sequence: Array[StringName]) -> void:
	sequence = new_sequence.duplicate()
	_rebuild()


func _on_spell_reset() -> void:
	sequence.clear()
	_rebuild()
