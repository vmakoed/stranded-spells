extends Room


var spell_switches_count: int


@onready var spell_switches: Node = %SpellSwitches


func _ready() -> void:
	super()
	spell_switches_count = spell_switches.get_child_count()


func _ready_active_level() -> void:
	super()
	door_left.open()


func _ready_cleared_level() -> void:
	super()
	for spell_switch in spell_switches.get_children():
		spell_switch.switch_off()


func _on_spell_switch_swithed_off() -> void:
	spell_switches_count -= 1
	if spell_switches_count == 0: _clear_level()
