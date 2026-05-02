extends Node

@export var player: RigidBody2D
@export var player_input: Node
@export var muzzle: Marker2D
@export var muzzle_flash: Node
@export var animator: Node

@export var pellet_count := 8
@export var spread_angle := 15.0
@export var max_distance := 1000.0

@export var recoil_force := 800.0
@export var fire_rate := 0.4

@export var trail_scene: PackedScene
@export var smoke_scene: PackedScene

var can_shoot := true


# =========================
# Input
# =========================
func _process(_delta):
	if not player_input or not player_input.is_aiming:
		return

	if Input.is_action_just_pressed("shoot"):
		try_shoot()


# =========================
# Shooting control
# =========================
func try_shoot():
	if not can_shoot:
		return

	can_shoot = false
	shoot()

	await get_tree().create_timer(fire_rate).timeout
	can_shoot = true


# =========================
# Core shooting logic
# =========================
func shoot():
	if not player or not muzzle:
		return

	var space_state = player.get_world_2d().direct_space_state

	# Dirección base del arma
	var base_dir = Vector2.RIGHT.rotated(muzzle.global_rotation)

	# Disparo de pellets
	for i in range(pellet_count):
		fire_pellet(space_state, base_dir)

	# Efectos
	trigger_flash()
	apply_recoil(base_dir)
	spawn_smoke(base_dir)


# =========================
# Pellet logic
# =========================
func fire_pellet(space_state, base_dir: Vector2):
	var spread = deg_to_rad(spread_angle)
	var angle_offset = randf_range(-spread, spread)

	var dir = base_dir.rotated(angle_offset)

	var from = muzzle.global_position
	var to = from + dir * max_distance

	var query := PhysicsRayQueryParameters2D.create(from, to)
	query.collide_with_areas = true
	query.collide_with_bodies = true

	var result = space_state.intersect_ray(query)

	var hit_pos = to

	if result:
		hit_pos = result.position
		# futuro: daño

	spawn_trail(from, hit_pos)


# =========================
# Recoil
# =========================
func apply_recoil(base_dir: Vector2):
	# Físico
	player.apply_force_custom(-base_dir * recoil_force)

	# Visual
	if animator and animator.has_method("apply_visual_recoil"):
		animator.apply_visual_recoil()


# =========================
# Visual effects
# =========================
func trigger_flash():
	if muzzle_flash and muzzle_flash.has_method("trigger"):
		muzzle_flash.trigger()


func spawn_trail(from: Vector2, to: Vector2):
	if not trail_scene:
		return

	var trail = trail_scene.instantiate()
	get_tree().current_scene.add_child(trail)

	trail.setup(from, to)
	trail.width = randf_range(1.5, 3.0)


func spawn_smoke(base_dir: Vector2):
	if not smoke_scene:
		return

	var smoke = smoke_scene.instantiate()
	get_tree().current_scene.add_child(smoke)

	smoke.setup(muzzle.global_position, base_dir)
