extends CharacterBody2D

@export var push_strength := 900.0
@export var max_speed := 400.0
@export var friction := 3.5
@export var turn_strength := 3.0

@onready var input_area: Area2D = $InputArea

var dragging := false
var last_mouse_pos := Vector2.ZERO

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if is_mouse_inside_input_area():
				dragging = true
				last_mouse_pos = get_global_mouse_position()
		else:
			dragging = false

	if event is InputEventMouseMotion and dragging:
		var current_mouse = get_global_mouse_position()
		var delta = current_mouse - last_mouse_pos
		last_mouse_pos = current_mouse

		apply_gesture(delta)

func is_mouse_inside_input_area() -> bool:
	var space_state = get_world_2d().direct_space_state

	var query := PhysicsPointQueryParameters2D.new()
	query.position = get_global_mouse_position()
	query.collide_with_areas = true
	query.collide_with_bodies = false

	var result = space_state.intersect_point(query)

	for r in result:
		if r.collider == input_area:
			return true

	return false

func apply_gesture(delta: Vector2):
	if delta.length() < 1:
		return

	var gesture_dir = -(delta).normalized()

	var forward = Vector2.UP.rotated(rotation)
	var right = Vector2.RIGHT.rotated(rotation)

	var forward_amount = forward.dot(gesture_dir)
	var turn_amount = right.dot(gesture_dir)

	velocity += forward * forward_amount * push_strength * get_process_delta_time()
	rotation += turn_amount * turn_strength * get_process_delta_time()

	if velocity.length() > max_speed:
		velocity = velocity.normalized() * max_speed


func _physics_process(delta):
	velocity = velocity.lerp(Vector2.ZERO, friction * delta)
	move_and_slide()
