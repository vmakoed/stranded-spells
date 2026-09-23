class_name EquippedSpellPanel
extends CenterContainer


@onready var prepare_texture: Control = %PrepareTexture
@onready var prepare_label: Label = %PrepareLabel
@onready var cast_texture: Control = %CastTexture
@onready var spell_label: Label = %SpellLabel


func _ready() -> void:
	visible = false
	_show_equipped(null)
	GameUIBridge.inventory_changed.connect(_on_inventory_changed)
	GameUIBridge.spell_equipped.connect(_show_equipped)
	GameUIBridge.spell_reset.connect(_show_equipped.bind(null))


func _on_inventory_changed(items: Array[Player.Item]) -> void:
	visible = Player.Item.BOOK in items


func _show_equipped(spell: Variant) -> void:
	var has_spell := spell != null
	prepare_texture.visible = not has_spell
	prepare_label.visible = not has_spell
	cast_texture.visible = has_spell
	spell_label.visible = has_spell
	if has_spell: spell_label.text = CastInputPanel.SPELL_LABELS[spell]
