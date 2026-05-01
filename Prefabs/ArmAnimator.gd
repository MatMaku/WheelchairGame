extends Node2D

@export var player: CharacterBody2D
@export var input_area: Area2D

@export var left_arm: Sprite2D
@export var right_arm: Sprite2D

@export var left_frames: Array[Texture2D]
@export var right_frames: Array[Texture2D]

var dragging := false


func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and is_mouse_inside_input_area():
			dragging = true
		else:
			dragging = false

func _process(_delta):
	if not dragging:
		set_idle()
		return

	if not is_mouse_inside_input_area():
		set_idle()
		dragging = false
		return

	update_arms()

func update_arms():
	var mouse_pos = player.get_global_mouse_position()
	var player_pos = player.global_position

	var dir = (mouse_pos - player_pos).normalized()

	var forward = Vector2.UP.rotated(player.rotation)
	var right = Vector2.RIGHT.rotated(player.rotation)

	var forward_amount = forward.dot(dir)
	var turn_amount = right.dot(dir)

	var forward_threshold := 0.9

	if forward_amount > forward_threshold:
		set_max_frames()
		return

	var left_value = forward_amount + turn_amount
	var right_value = forward_amount - turn_amount

	set_arm_state(left_value, left_arm, left_frames)
	set_arm_state(right_value, right_arm, right_frames)

func set_arm_state(value: float, arm: Sprite2D, frames: Array):
	var t = (value + 1.0) * 0.5  # map -1..1 → 0..1
	t = clamp(t, 0.0, 1.0)

	var index = int(t * 3.0) + 1
	index = clamp(index, 1, 4)

	arm.texture = frames[index]

func set_idle():
	if left_frames.size() > 0:
		left_arm.texture = left_frames[0]
	if right_frames.size() > 0:
		right_arm.texture = right_frames[0]

func set_max_frames():
	left_arm.texture = left_frames[left_frames.size() - 1]
	right_arm.texture = right_frames[right_frames.size() - 1]

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
