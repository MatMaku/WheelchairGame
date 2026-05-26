extends Node
class_name PlayerInput

@export var push_strength := 900.0
@export var turn_strength := 3.0

@onready var player: RigidBody2D = get_parent()
@onready var input_area: Area2D = player.get_node("InputArea")

var dragging := false
var last_mouse_pos := Vector2.ZERO
var is_aiming := false


func _ready() -> void:
	add_to_group("player_input")
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func set_enabled(enabled: bool) -> void:
	set_process_input(enabled)
	if not enabled:
		is_aiming = false
		dragging = false


func _input(event: InputEvent) -> void:
	handle_aim_input(event)
	handle_movement_input(event)


func handle_aim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		is_aiming = event.pressed
		dragging = false


func handle_movement_input(event: InputEvent) -> void:
	if is_aiming:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and is_mouse_inside_input_area():
			dragging = true
			last_mouse_pos = player.get_global_mouse_position()
		else:
			dragging = false

	if dragging and not is_mouse_inside_input_area():
		dragging = false
		return

	if event is InputEventMouseMotion and dragging:
		var current_mouse = player.get_global_mouse_position()
		var delta = current_mouse - last_mouse_pos
		last_mouse_pos = current_mouse
		apply_gesture(delta)


func apply_gesture(delta: Vector2) -> void:
	if delta.length() < 1:
		return

	var gesture_dir = delta.normalized()
	var forward = Vector2.UP.rotated(player.rotation)
	var right = Vector2.RIGHT.rotated(player.rotation)

	var forward_amount = forward.dot(gesture_dir)
	var turn_amount = right.dot(gesture_dir)

	player.apply_force_custom(forward * forward_amount * push_strength * get_process_delta_time())
	player.apply_torque_custom(turn_amount * turn_strength)


func is_mouse_inside_input_area() -> bool:
	var space_state = player.get_world_2d().direct_space_state

	var query := PhysicsPointQueryParameters2D.new()
	query.position = player.get_global_mouse_position()
	query.collide_with_areas = true
	query.collide_with_bodies = false

	var result = space_state.intersect_point(query)
	for r in result:
		if r.collider == input_area:
			return true
	return false
