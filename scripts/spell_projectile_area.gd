extends Area2D


const DAMAGE = 100.0
const DELETION_DELAY = 5.0


var active := true: set = _set_active
var velocity := Vector2.ZERO


func _physics_process(delta: float) -> void:
	position += velocity * delta


func _set_active(new_value: bool) -> void:
	if active == new_value: return
	active = new_value
	if active: return
	visible = false
	await get_tree().create_timer(DELETION_DELAY).timeout
	queue_free()


func _on_area_entered(area: Area2D) -> void:
	if not active: return
	if area is not HurtboxComponent: return
	area.damage(DAMAGE)
	active = false


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	active = false
