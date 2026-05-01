extends CharacterBody2D

@export var max_speed := 400.0
@export var forward_friction := 3.5
@export var lateral_friction := 12.0
@export var angular_damping := 6.0

var angular_velocity := 0.0

func apply_force(force: Vector2):
	velocity += force

func apply_torque(amount: float):
	angular_velocity += amount

func get_forward_speed() -> float:
	var forward = Vector2.UP.rotated(rotation)
	return velocity.dot(forward)

func get_angular_velocity() -> float:
	return angular_velocity


func _physics_process(delta):
	var forward = Vector2.UP.rotated(rotation)
	var right = Vector2.RIGHT.rotated(rotation)

	var forward_vel = forward * velocity.dot(forward)
	var lateral_vel = right * velocity.dot(right)

	forward_vel = forward_vel.lerp(Vector2.ZERO, forward_friction * delta)
	lateral_vel = lateral_vel.lerp(Vector2.ZERO, lateral_friction * delta)

	velocity = forward_vel + lateral_vel

	if velocity.length() > max_speed:
		velocity = velocity.normalized() * max_speed

	rotation += angular_velocity * delta
	angular_velocity = lerp(angular_velocity, 0.0, angular_damping * delta)

	move_and_slide()
