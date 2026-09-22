@tool
class_name Torch
extends Area2D

signal ignited

enum Facing { TOP, DOWN, LEFT, RIGHT, FLOOR }

const LIT_TOP_TEXTURE := preload("res://assets/textures/torch_1.png")
const LIT_SIDE_TEXTURE := preload("res://assets/textures/side_torch_1.png")
const LIT_FLOOR_TEXTURE := preload("res://assets/textures/candlestick_1_3.png")
const UNLIT_TOP_TEXTURE := preload("res://assets/textures/torch_unlit_top_v2.png")
const UNLIT_SIDE_TEXTURE := preload("res://assets/textures/torch_unlit_side_v2.png")
const UNLIT_FLOOR_TEXTURE := preload("res://assets/textures/candlestick_1_3_unlit.png")
const SPARK_SCENE := preload("res://scenes/torch_spark.tscn")
const LIGHT_ENERGY := 1.2
const FLARE_ENERGY := 2.4
const IGNITE_DURATION := 0.3
const SPREAD_DELAY := 0.15
const SPREAD_SPEED := 80.0
const SPREAD_RING_COLOR := Color(1, 0.7, 0.3, 0.35)

@export var facing: Facing = Facing.TOP:
	set(value):
		facing = value
		_apply()
		queue_redraw()

@export var lit := true:
	set(value):
		lit = value
		_apply()

@export_range(0, 256, 1, "suffix:px") var spread_radius := 64.0:
	set(value):
		spread_radius = value
		queue_redraw()

@onready var sprite: Sprite2D = %Sprite2D
@onready var light: PointLight2D = %PointLight2D

var _tween: Tween


func _ready() -> void:
	_apply()


func ignite() -> void:
	if lit: return
	lit = true
	if Engine.is_editor_hint(): return

	var targets := _spread_targets()
	light.energy = 0.0
	if _tween: _tween.kill()
	_tween = create_tween()
	if targets.is_empty():
		_tween.tween_property(light, "energy", LIGHT_ENERGY, IGNITE_DURATION)
	else:
		_tween.tween_property(light, "energy", FLARE_ENERGY, IGNITE_DURATION)
		_tween \
			.tween_property(light, "energy", LIGHT_ENERGY, SPREAD_DELAY) \
			.set_trans(Tween.TRANS_SINE) \
			.set_ease(Tween.EASE_OUT)
	ignited.emit()
	for target in targets:
		_launch_spark(target)


func _spread_targets() -> Array[Torch]:
	var targets: Array[Torch] = []
	if facing != Facing.FLOOR or spread_radius <= 0.0: return targets
	var radius_sq := spread_radius * spread_radius
	for torch: Torch in get_tree().get_nodes_in_group("torches"):
		if torch == self or torch.lit: continue
		if global_position.distance_squared_to(torch.global_position) > radius_sq: continue
		targets.append(torch)
	return targets


func _launch_spark(target: Torch) -> void:
	var spark: TorchSpark = SPARK_SCENE.instantiate()
	add_child(spark)
	spark.arrived.connect(func() -> void:
		if is_instance_valid(target): target.ignite())
	spark.fly(target.global_position, SPREAD_DELAY, SPREAD_SPEED)


func _draw() -> void:
	if not Engine.is_editor_hint(): return
	if facing != Facing.FLOOR or spread_radius <= 0.0: return
	draw_arc(Vector2.ZERO, spread_radius, 0.0, TAU, 48, SPREAD_RING_COLOR, 1.0)


func _apply() -> void:
	if not is_node_ready():
		return
	sprite.visible = facing != Facing.DOWN
	sprite.flip_h = facing == Facing.RIGHT
	sprite.texture = _texture()
	light.enabled = lit
	light.energy = LIGHT_ENERGY


func _texture() -> Texture2D:
	match facing:
		Facing.FLOOR:
			return LIT_FLOOR_TEXTURE if lit else UNLIT_FLOOR_TEXTURE
		Facing.LEFT, Facing.RIGHT:
			return LIT_SIDE_TEXTURE if lit else UNLIT_SIDE_TEXTURE
		_:
			return LIT_TOP_TEXTURE if lit else UNLIT_TOP_TEXTURE
