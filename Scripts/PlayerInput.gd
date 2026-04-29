extends Node

@export var push_strength := 900.0
@export var turn_strength := 3.0

@onready var player: CharacterBody2D = get_parent()
@onready var input_area: Area2D = player.get_node("InputArea")

var dragging := false
var last_mouse_pos := Vector2.ZERO


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _input(event):
	# 🟢 CLICK
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if is_mouse_inside_input_area():
				dragging = true
				last_mouse_pos = player.get_global_mouse_position()
		else:
			dragging = false

	# 🔴 CORTE SI SALE DEL ÁREA
	if dragging and not is_mouse_inside_input_area():
		dragging = false
		return

	# 🟡 MOVIMIENTO
	if event is InputEventMouseMotion and dragging:
		var current_mouse = player.get_global_mouse_position()
		var delta = current_mouse - last_mouse_pos
		last_mouse_pos = current_mouse

		apply_gesture(delta)


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


func apply_gesture(delta: Vector2):
	if delta.length() < 1:
		return

	# ✅ CORREGIDO: ya NO invertido
	var gesture_dir = delta.normalized()

	var forward = Vector2.UP.rotated(player.rotation)
	var right = Vector2.RIGHT.rotated(player.rotation)

	var forward_amount = forward.dot(gesture_dir)
	var turn_amount = right.dot(gesture_dir)

	# 🔹 Aplicar fuerzas al sistema físico
	player.apply_force(forward * forward_amount * push_strength * get_process_delta_time())
	player.apply_torque(turn_amount * turn_strength)
