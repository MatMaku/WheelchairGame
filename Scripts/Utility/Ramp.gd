extends Area2D

@export var slope_strength := 600.0
@export var use_node_rotation := true
@export var slope_direction := Vector2.DOWN

# cuánto reducimos la fuerza al subir
@export var uphill_factor := 0.3  # 0 = sin resistencia, 1 = igual que bajando


# =========================
# Physics
# =========================
func _physics_process(delta):
	var bodies = get_overlapping_bodies()
	if bodies.is_empty():
		return

	var dir = get_slope_direction()

	for body in bodies:
		if not body or not body.has_method("apply_force_custom"):
			continue

		var force_multiplier = 1.0

		if body.linear_velocity.length() > 0.1:
			var alignment = body.linear_velocity.normalized().dot(dir)

			# Si está subiendo (opuesto a la rampa)
			if alignment < 0:
				# reducimos la fuerza
				force_multiplier = lerp(1.0, uphill_factor, -alignment)

		body.apply_force_custom(dir * slope_strength * force_multiplier * delta)


# =========================
# Dirección de la rampa
# =========================
func get_slope_direction() -> Vector2:
	if use_node_rotation:
		return Vector2.DOWN.rotated(global_rotation).normalized()
	else:
		return slope_direction.normalized()
