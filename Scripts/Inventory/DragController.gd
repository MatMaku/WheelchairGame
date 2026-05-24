extends Node
class_name DragController

@export var inventory_system: InventorySystem
@export var shotgun_ui: ShotgunUI
@export var drag_layer: Node
@export var items_container: Node

var current_item: Node2D = null
var drag_offset: Vector2 = Vector2.ZERO

var drag_started_from_shotgun := false
var shotgun_lock_until_exit := false


# --- Input ---
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_try_start_drag()
		else:
			_end_drag()
		return

	if event is InputEventMouseMotion and current_item:
		_update_drag()


func _mouse_pos() -> Vector2:
	return get_viewport().get_mouse_position()


# --- Drag ---
func _try_start_drag() -> void:
	if current_item:
		return

	drag_started_from_shotgun = false
	shotgun_lock_until_exit = false

	var item: Node2D = null

	if is_instance_valid(inventory_system):
		item = inventory_system.pick_item_at_mouse()

	if item == null and is_instance_valid(shotgun_ui):
		item = _pick_draggable_in_tree(shotgun_ui)
		if item:
			drag_started_from_shotgun = true
			shotgun_lock_until_exit = true

	if item == null:
		return

	current_item = item
	drag_offset = current_item.global_position - _mouse_pos()

	if is_instance_valid(inventory_system):
		inventory_system.set_dragged_item(current_item)

	if drag_started_from_shotgun:
		# Mantener ammo_side_sprite desde el primer frame (sin flicker)
		if current_item.has_method("set_in_shotgun_area"):
			current_item.set_in_shotgun_area(true)
			reset_drag_offset_for(current_item)

		shotgun_ui.on_item_drag_started(current_item)

	current_item.reparent(drag_layer)
	current_item.z_index = 1000


func _update_drag() -> void:
	current_item.global_position = _mouse_pos() + drag_offset

	if not is_instance_valid(shotgun_ui):
		return

	var inside: bool = shotgun_ui.is_item_in_interaction_area(current_item)
	var effective_inside := inside

	if drag_started_from_shotgun and shotgun_lock_until_exit:
		if inside:
			effective_inside = true
		else:
			shotgun_lock_until_exit = false
			effective_inside = false

	if current_item.has_method("set_in_shotgun_area"):
		current_item.set_in_shotgun_area(effective_inside)


func _end_drag() -> void:
	if not current_item:
		return

	var item := current_item
	current_item = null

	drag_started_from_shotgun = false
	shotgun_lock_until_exit = false

	if is_instance_valid(inventory_system):
		inventory_system.set_dragged_item(null)

	if item.has_method("set_in_shotgun_area"):
		item.set_in_shotgun_area(false)

	if is_instance_valid(shotgun_ui) and shotgun_ui.try_insert_item(item):
		if is_instance_valid(inventory_system):
			inventory_system.on_item_moved_to_shotgun(item)

		item.reparent(shotgun_ui)
		item.z_index = 0
		return

	if is_instance_valid(shotgun_ui) and shotgun_ui.is_item_in_interaction_area(item):
		item.reparent(items_container)
		items_container.move_child(item, items_container.get_child_count() - 1)

		if is_instance_valid(inventory_system):
			inventory_system.on_item_dropped_inside(item)

		item.z_index = 0
		return

	item.reparent(items_container)
	items_container.move_child(item, items_container.get_child_count() - 1)

	if is_instance_valid(inventory_system):
		inventory_system.on_item_drop_finished(item)

	item.z_index = 0


# --- Helpers ---
func reset_drag_offset_for(item: Node2D) -> void:
	if item != current_item:
		return
	drag_offset = current_item.global_position - _mouse_pos()


func _pick_draggable_in_tree(root: Node) -> Node2D:
	for i in range(root.get_child_count() - 1, -1, -1):
		var child := root.get_child(i)

		if child is Node2D and child.has_method("is_mouse_over") and child.is_mouse_over():
			return child

		if child.get_child_count() > 0:
			var found := _pick_draggable_in_tree(child)
			if found:
				return found

	return null
