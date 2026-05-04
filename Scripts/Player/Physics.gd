extends RigidBody2D

@export var max_speed := 800.0
@export var lateral_friction := 12.0
@export var angular_damping_custom := 6.0


# =========================
# External API
# =========================
func apply_force_custom(force: Vector2):
	apply_central_impulse(force)


func apply_torque_custom(amount: float):
	apply_torque_impulse(amount)


func get_forward_speed() -> float:
	var forward = Vector2.UP.rotated(rotation)
	return linear_velocity.dot(forward)


func get_angular_velocity_custom() -> float:
	return angular_velocity


# =========================
# Physics
# =========================
func _physics_process(delta):
	var right = Vector2.RIGHT.rotated(rotation)

	# Separar solo componente lateral
	var lateral_speed = linear_velocity.dot(right)

	# Reducir movimiento lateral (efecto ruedas)
	lateral_speed = lerp(lateral_speed, 0.0, lateral_friction * delta)

	# Reconstruir velocidad conservando forward intacto
	var forward_component = linear_velocity - right * linear_velocity.dot(right)
	var lateral_component = right * lateral_speed

	linear_velocity = forward_component + lateral_component

	# Clamp velocidad máxima
	if linear_velocity.length() > max_speed:
		linear_velocity = linear_velocity.normalized() * max_speed

	# Damping angular suave (opcional)
	angular_velocity = lerp(angular_velocity, 0.0, angular_damping_custom * delta)
