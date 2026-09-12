class_name DeathShatter
extends Node2D


const GRID = 4
const SHARD_DURATION = 0.55
const SHARD_FADE_DURATION = 0.3
const SHARD_SPEED_MIN = 30.0
const SHARD_SPEED_MAX = 60.0
const SHARD_ANGLE_JITTER = deg_to_rad(25.0)
const SHARD_SPIN_MAX = PI * 0.75
const RECOLOR_DURATION = 0.15
const RING_DURATION = 0.3
const RING_END_SCALE = 0.3125
const FLASH_SHADER = preload("res://assets/shaders/flash.gdshader")


@onready var ring: Sprite2D = %Ring
@onready var shards: Node2D = %Shards


## Plays the shatter VFX: the ring expands and [param sprite] is split into a
## [constant GRID]×[constant GRID] grid of shards that fly outward and fade.[br]
## [param sprite] is an [AnimatedSprite2D] (uses its current frame) or a plain
## [Sprite2D] (uses its [member Sprite2D.texture]). Frees itself when finished.
func play(sprite: Node2D) -> void:
	var tween := create_tween().set_parallel(true)
	_animate_ring(tween)

	var shard_material := _build_shards(sprite)
	if shard_material != null:
		tween.tween_property(
			shard_material,
			"shader_parameter/flash_amount",
			0.0,
			RECOLOR_DURATION
		)
		for shard: Sprite2D in shards.get_children():
			_animate_shard(tween, shard)

	tween.finished.connect(queue_free)


func _animate_ring(tween: Tween) -> void:
	tween \
		.tween_property(ring, "scale", Vector2.ONE * RING_END_SCALE, RING_DURATION) \
		.set_trans(Tween.TRANS_CUBIC) \
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(ring, "modulate:a", 0.0, RING_DURATION)


func _frame_texture(sprite: Node2D) -> Texture2D:
	if sprite is Sprite2D:
		return sprite.texture
	if sprite is AnimatedSprite2D:
		if sprite.sprite_frames == null: return null
		if not sprite.sprite_frames.has_animation(sprite.animation): return null
		return sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	return null


func _build_shards(sprite: Node2D) -> ShaderMaterial:
	var frame_texture := _frame_texture(sprite)
	if frame_texture == null: return null

	var atlas: Texture2D = frame_texture
	var region := Rect2(Vector2.ZERO, frame_texture.get_size())
	if frame_texture is AtlasTexture:
		atlas = frame_texture.atlas
		region = frame_texture.region

	var shard_material := ShaderMaterial.new()
	shard_material.shader = FLASH_SHADER
	shard_material.set_shader_parameter("flash_amount", 1.0)

	var cell := region.size / GRID
	var sprite_scale := sprite.global_scale
	for row in GRID:
		for col in GRID:
			var shard_texture := AtlasTexture.new()
			shard_texture.atlas = atlas
			shard_texture.region = Rect2(region.position + Vector2(col, row) * cell, cell)
			shard_texture.filter_clip = true

			var shard := Sprite2D.new()
			shard.texture = shard_texture
			shard.material = shard_material
			shard.flip_h = sprite.flip_h
			shard.scale = sprite_scale
			var offset := ((Vector2(col, row) + Vector2(0.5, 0.5)) * cell - region.size / 2.0) * sprite_scale
			if sprite.flip_h: offset.x = -offset.x
			shard.position = offset
			shards.add_child(shard)

	return shard_material


func _animate_shard(tween: Tween, shard: Sprite2D) -> void:
	var direction := shard.position.normalized()
	if direction.is_zero_approx():
		direction = Vector2.from_angle(randf() * TAU)
	direction = direction.rotated(randf_range(-SHARD_ANGLE_JITTER, SHARD_ANGLE_JITTER))
	var speed := randf_range(SHARD_SPEED_MIN, SHARD_SPEED_MAX)

	tween \
		.tween_property(shard, "position", shard.position + direction * speed * SHARD_DURATION, SHARD_DURATION) \
		.set_trans(Tween.TRANS_EXPO) \
		.set_ease(Tween.EASE_OUT)
	tween \
		.tween_property(shard, "rotation", randf_range(-SHARD_SPIN_MAX, SHARD_SPIN_MAX), SHARD_DURATION) \
		.set_trans(Tween.TRANS_CUBIC) \
		.set_ease(Tween.EASE_OUT)
	tween \
		.tween_property(shard, "modulate:a", 0.0, SHARD_FADE_DURATION) \
		.set_delay(SHARD_DURATION - SHARD_FADE_DURATION)
