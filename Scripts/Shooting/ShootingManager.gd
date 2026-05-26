extends Node
class_name ShootingManager

@export var player: RigidBody2D
@export var player_input: PlayerInput
@export var muzzle: Marker2D
@export var muzzle_flash: Node
@export var animator: Node

@export var shotgun_ui: ShotgunUI
@export var shotgun_ui_group := "shotgun_ui"

@export var pellet_count := 8
@export var spread_angle := 15.0
@export var max_distance := 1000.0

@export var recoil_force := 800.0
@export var fire_rate := 0.4

@export var trail_scene: PackedScene
@export var smoke_scene: PackedScene

var can_shoot := true


func _ready() -> void:
	add_to_group("shooting_manager")
	_resolve_shotgun_ui()


func set_enabled(enabled: bool) -> void:
	set_process(enabled)
	if not enabled:
		can_shoot = true


func _process(_delta: float) -> void:
	if shotgun_ui == null:
		_resolve_shotgun_ui()

	if not player_input or not player_input.is_aiming:
		return

	if Input.is_action_just_pressed("shoot"):
		try_shoot()


func _resolve_shotgun_ui() -> void:
	var node := get_tree().get_first_node_in_group(shotgun_ui_group)
	shotgun_ui = node as ShotgunUI


func try_shoot() -> void:
	if not can_shoot:
		return

	# Si todavía no existe el ShotgunUI, no puede disparar
	if shotgun_ui == null:
		return

	# Consume 1 bala NEW; si no hay, no dispara
	if not shotgun_ui.fire_once():
		return

	can_shoot = false
	shoot()

	await get_tree().create_timer(fire_rate).timeout
	can_shoot = true


func shoot() -> void:
	if not player or not muzzle:
		return

	var space_state = player.get_world_2d().direct_space_state
	var base_dir = Vector2.RIGHT.rotated(muzzle.global_rotation)

	for i in range(pellet_count):
		fire_pellet(space_state, base_dir)

	trigger_flash()
	apply_recoil(base_dir)
	spawn_smoke(base_dir)


func fire_pellet(space_state, base_dir: Vector2) -> void:
	var spread = deg_to_rad(spread_angle)
	var angle_offset = randf_range(-spread, spread)
	var dir = base_dir.rotated(angle_offset)

	var from = muzzle.global_position
	var to = from + dir * max_distance

	var query := PhysicsRayQueryParameters2D.create(from, to)
	query.collide_with_areas = false
	query.collide_with_bodies = true

	var result = space_state.intersect_ray(query)
	var hit_pos = to
	if result:
		hit_pos = result.position

	spawn_trail(from, hit_pos)


func apply_recoil(base_dir: Vector2) -> void:
	player.apply_force_custom(-base_dir * recoil_force)
	if animator and animator.has_method("apply_visual_recoil"):
		animator.apply_visual_recoil()


func trigger_flash() -> void:
	if muzzle_flash and muzzle_flash.has_method("trigger"):
		muzzle_flash.trigger()


func spawn_trail(from: Vector2, to: Vector2) -> void:
	if not trail_scene:
		return
	var trail = trail_scene.instantiate()
	get_tree().current_scene.add_child(trail)
	trail.setup(from, to)
	trail.width = randf_range(1.5, 3.0)


func spawn_smoke(base_dir: Vector2) -> void:
	if not smoke_scene:
		return
	var smoke = smoke_scene.instantiate()
	get_tree().current_scene.add_child(smoke)
	smoke.setup(muzzle.global_position, base_dir)
