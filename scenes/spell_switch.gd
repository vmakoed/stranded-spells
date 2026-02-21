extends StaticBody2D


signal swithed_off


@export var spell: SpellDefinitions.Spell
var on := true
@onready var animated_sprite: AnimatedSprite2D = find_child("AnimatedSprite2D")


func _ready() -> void:
	animated_sprite.play("on")


func switch_off() -> void:
	animated_sprite.play("off")
	swithed_off.emit()


func receive_push(_direction: Vector2) -> void:
	_receive_spell(SpellDefinitions.Spell.PUSH)


func receive_frost(_direction: Vector2) -> void:
	_receive_spell(SpellDefinitions.Spell.FROST)


func receive_shock(_direction: Vector2) -> void:
	_receive_spell(SpellDefinitions.Spell.SHOCK)


func receive_fire(_direction: Vector2) -> void:
	_receive_spell(SpellDefinitions.Spell.FIRE)


func _receive_spell(received_spell: SpellDefinitions.Spell) -> void:
	if spell == received_spell and on: switch_off()
