class_name PromptsPanel
extends GridContainer


const FONT_SIZE = 32
const REVEAL_COLOR = Color(0.5, 0.72, 0.78, 1.0)	# attack teal, same as spell highlights
const REVEAL_BLINKS = 4
const REVEAL_BLINK_DURATION = 0.15
const REVEAL_HOLD_DURATION = 0.6
const REVEAL_FADE_DURATION = 1.0


const ROWS: Array[Dictionary] = [
	{ "button": "LS:", "text": "Move" },
	{ "button": "Start:", "text": "Pause" },
	{ "button": "RS:", "text": "Aim", "requires": Player.Item.WAND },
	{ "button": "RT:", "text": "Sacred Flame", "requires": Player.Item.WAND },
	{ "button": "LT:", "text": "Cast Spell", "requires": Player.Item.BOOK },
	{ "button": "ABXY:", "text": "Select Spell", "requires": Player.Item.BOOK },
	{ "button": "RB:", "text": "Reset Spell", "requires": Player.Item.BOOK },
]


var _shown: Dictionary[int, Array] = {}
var _reveal_tweens: Dictionary[int, Tween] = {}


func _ready() -> void:
	columns = 2
	for index in ROWS.size():
		if ROWS[index].has("requires"): continue
		_add_row(index)
	GameUIBridge.inventory_changed.connect(_on_inventory_changed)


func _on_inventory_changed(items: Array[Player.Item]) -> void:
	for index in ROWS.size():
		var row := ROWS[index]
		if not row.has("requires"): continue
		var should_show: bool = row["requires"] in items
		if should_show == _shown.has(index): continue
		if should_show:
			_add_row(index)
			_flash(index)
		else:
			_remove_row(index)


func _add_row(index: int) -> void:
	var row := ROWS[index]
	_shown[index] = [
		_make_label(row["button"], HORIZONTAL_ALIGNMENT_RIGHT),
		_make_label(row["text"], HORIZONTAL_ALIGNMENT_LEFT)
	]


func _remove_row(index: int) -> void:
	_kill_tween(index)
	for label: Label in _shown[index]:
		remove_child(label)
		label.queue_free()
	_shown.erase(index)


func _make_label(text: String, alignment: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = alignment
	label.add_theme_font_size_override(&"font_size", FONT_SIZE)
	add_child(label)
	return label


func _flash(index: int) -> void:
	_kill_tween(index)
	var labels: Array = _shown[index]
	for label: Label in labels: label.modulate = REVEAL_COLOR
	var tween := create_tween()
	for blink in REVEAL_BLINKS:
		_tween_row(tween, labels, Color.WHITE, REVEAL_BLINK_DURATION)
		_tween_row(tween, labels, REVEAL_COLOR, REVEAL_BLINK_DURATION)
	tween.tween_interval(REVEAL_HOLD_DURATION)
	_tween_row(tween, labels, Color.WHITE, REVEAL_FADE_DURATION)
	_reveal_tweens[index] = tween


func _tween_row(tween: Tween, labels: Array, color: Color, duration: float) -> void:
	tween.tween_property(labels[0], "modulate", color, duration)
	tween.parallel().tween_property(labels[1], "modulate", color, duration)


func _kill_tween(index: int) -> void:
	var tween: Tween = _reveal_tweens.get(index)
	if tween: tween.kill()
	_reveal_tweens.erase(index)
