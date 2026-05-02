extends Area2D

@export var slope_strength := 600.0
@export var use_node_rotation := true
@export var slope_direction := Vector2.DOWN


# =========================
# Physics
# =========================
func _physics_process(delta):
	var bodies = get_overlapping_bodies()

	if bodies.is_empty():
		return

	var dir = get_slope_direction()

	for body in bodies:
		if body and body.has_method("apply_force_custom"):
			body.apply_force_custom(dir * slope_strength * delta)


# =========================
# Dirección de la rampa
# =========================
func get_slope_direction() -> Vector2:
	if use_node_rotation:
		return Vector2.DOWN.rotated(global_rotation).normalized()
	else:
		return slope_direction.normalized()
