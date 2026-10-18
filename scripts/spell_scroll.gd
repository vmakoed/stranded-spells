class_name SpellScroll
extends Area2D


@export var spell: CastInputPanel.Spell
@export var save_id := ""


@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	if GameState.get_flag(self, false):
		queue_free()
		return
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is not Player: return
	body.learn_spell(spell)
	GameState.set_flag(self, true)
	body.play_pickup_sound()
	body.show_hint(sprite.texture)
	queue_free()
