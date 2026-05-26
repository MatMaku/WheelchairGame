extends Node2D
class_name DraggableItem

@onready var sprite: Sprite2D = $Sprite2D

@export var collision_size: Vector2 = Vector2(32, 32)

@export var heal_sprite: Texture2D
@export var key_sprite: Texture2D

@export var ammo_new_front_sprite: Texture2D
@export var ammo_new_side_sprite: Texture2D
@export var ammo_empty_front_sprite: Texture2D
@export var ammo_empty_side_sprite: Texture2D

var inventory_system: InventorySystem = null
var item_type: ItemData.ItemType = ItemData.ItemType.AMMO
var ammo_state: ItemData.AmmoState = ItemData.AmmoState.NEW

var in_shotgun_area := false
var is_in_slot := false
var is_discarding := false


# Data
func set_data(data: ItemData) -> void:
	item_type = data.type
	ammo_state = data.ammo_state
	global_position = data.position
	update_visual()


func get_data() -> ItemData:
	var data := ItemData.new()
	data.type = item_type
	data.position = global_position
	data.ammo_state = ammo_state
	return data


# State
func set_in_shotgun_area(value: bool) -> void:
	if in_shotgun_area == value:
		return

	in_shotgun_area = value
	update_visual()

	global_position = get_viewport().get_mouse_position()
	if inventory_system:
		inventory_system.reset_drag_offset(self)


func set_in_slot(value: bool) -> void:
	if is_in_slot == value:
		return

	is_in_slot = value
	update_visual()


func set_ammo_state(value: ItemData.AmmoState) -> void:
	if ammo_state == value:
		return

	ammo_state = value
	update_visual()


func is_ammo_new() -> bool:
	return item_type == ItemData.ItemType.AMMO and ammo_state == ItemData.AmmoState.NEW


func is_ammo_empty() -> bool:
	return item_type == ItemData.ItemType.AMMO and ammo_state == ItemData.AmmoState.EMPTY


# Visual
func update_visual() -> void:
	sprite.texture = _get_current_texture()


func _get_current_texture() -> Texture2D:
	match item_type:
		ItemData.ItemType.HEAL:
			return heal_sprite
		ItemData.ItemType.AMMO:
			return _get_ammo_texture()
		ItemData.ItemType.KEY:
			return key_sprite
		_:
			return null


func _get_ammo_texture() -> Texture2D:
	var use_side := is_in_slot or in_shotgun_area

	if ammo_state == ItemData.AmmoState.EMPTY:
		if use_side:
			return ammo_empty_side_sprite
		return ammo_empty_front_sprite

	# NEW
	if use_side:
		return ammo_new_side_sprite
	return ammo_new_front_sprite


# Discard / Fall
func start_discard_fall(speed: float = 900.0, margin: float = 150.0) -> void:
	if is_discarding:
		return
	is_discarding = true

	in_shotgun_area = false
	is_in_slot = false
	update_visual()

	var vp_h: float = get_viewport_rect().size.y
	var target: Vector2 = Vector2(global_position.x, vp_h + margin)
	var dist: float = abs(target.y - global_position.y)
	var duration: float = maxf(0.05, dist / speed)

	var tw: Tween = create_tween()
	tw.tween_property(self, "global_position", target, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(queue_free)


# Mouse
func is_mouse_over() -> bool:
	if is_discarding:
		return false
	if not sprite or not sprite.texture:
		return false

	var size := sprite.texture.get_size() * sprite.scale
	var rect := Rect2(global_position - size * 0.5, size)
	return rect.has_point(get_viewport().get_mouse_position())
