extends Node2D

@export var player: RigidBody2D
@export var input_area: Area2D
@export var player_input: Node

# Visual groups
@export var movement_visuals: Node2D
@export var aim_visuals: Node2D

# Movement arms
@export var left_arm: Sprite2D
@export var right_arm: Sprite2D
@export var left_frames: Array[Texture2D]
@export var right_frames: Array[Texture2D]

# Aiming
@export var torso_aim: Node2D
@export var cuerpo_sprite: Sprite2D
@export var aim_speed := 12.0
@export var aim_reset_speed := 10.0

# Shooting (visual recoil)
@export var recoil_distance := 5.0
@export var recoil_speed := 20.0

# Arm smoothing
@export var arm_lerp_speed := 12.0

var recoil_offset := 0.0

var left_arm_value := 0.0
var right_arm_value := 0.0

var dragging := false
var was_aiming := false

var base_torso_rotation := 0.0


func _ready():
	base_torso_rotation = torso_aim.global_rotation


func _process(delta):
	# Recoil update
	recoil_offset = lerp(recoil_offset, 0.0, recoil_speed * delta)
	cuerpo_sprite.offset.y = recoil_offset

	# Visual state switching
	if player_input.is_aiming != was_aiming:
		update_visual_state(player_input.is_aiming)
		was_aiming = player_input.is_aiming

	# Aiming mode
	if player_input.is_aiming:
		update_aiming(delta)
		return
	else:
		reset_torso_rotation(delta)

	# Movement mode
	if not dragging:
		set_idle()
		return

	if not is_mouse_inside_input_area():
		set_idle()
		dragging = false
		return

	update_arms(delta)


func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and is_mouse_inside_input_area() and not player_input.is_aiming:
			dragging = true
		else:
			dragging = false


# =========================
# Visual state management
# =========================
func update_visual_state(is_aiming: bool):
	movement_visuals.visible = not is_aiming
	aim_visuals.visible = is_aiming


# =========================
# Aiming system
# =========================
func update_aiming(delta):
	var mouse_pos = player.get_global_mouse_position()
	var dir = mouse_pos - player.global_position

	if dir.length() < 1:
		return

	var target_angle = dir.angle()
	var forward_angle = player.global_rotation - PI / 2

	var relative_angle = wrapf(target_angle - forward_angle, -PI, PI)

	var max_angle = deg_to_rad(45)
	relative_angle = clamp(relative_angle, -max_angle, max_angle)

	var final_angle = forward_angle + relative_angle - PI / 2

	torso_aim.global_rotation = lerp_angle(
		torso_aim.global_rotation,
		final_angle,
		aim_speed * delta
	)


# =========================
# Reset torso when not aiming
# =========================
func reset_torso_rotation(delta):
	torso_aim.global_rotation = lerp_angle(
		torso_aim.global_rotation,
		base_torso_rotation,
		aim_reset_speed * delta
	)


# =========================
# Shooting (visual recoil)
# =========================
func apply_visual_recoil():
	recoil_offset = -recoil_distance


# =========================
# Arm animation system
# =========================
func update_arms(delta):
	var mouse_pos = player.get_global_mouse_position()
	var player_pos = player.global_position

	var delta_pos = mouse_pos - player_pos

	if delta_pos.length() < 1:
		return

	var dir = delta_pos.normalized()

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

	left_arm_value = lerp(left_arm_value, left_value, arm_lerp_speed * delta)
	right_arm_value = lerp(right_arm_value, right_value, arm_lerp_speed * delta)

	set_arm_state(left_arm_value, left_arm, left_frames)
	set_arm_state(right_arm_value, right_arm, right_frames)


func set_arm_state(value: float, arm: Sprite2D, frames: Array):
	var t = (value + 1.0) * 0.5
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


# =========================
# Utility
# =========================
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
