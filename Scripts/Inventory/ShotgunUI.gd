extends Node2D
class_name ShotgunUI

@onready var interaction_area: Control = $InteractionArea
var slots: Array[ShotgunSlot] = []


func _ready() -> void:
	slots.clear()
	for child in get_children():
		if child is ShotgunSlot:
			slots.append(child)


# --- Queries ---
func is_item_in_interaction_area(item: Node2D) -> bool:
	return interaction_area.get_global_rect().intersects(_get_item_logic_rect(item))

func get_loaded_new_ammo_count() -> int:
	var count := 0
	for slot in slots:
		if slot.has_new_ammo_loaded():
			count += 1
	return count


# --- Insert / Drag ---
func try_insert_item(item: Node2D) -> bool:
	for slot in slots:
		if slot.can_accept(item) and slot.is_item_overlapping(item):
			slot.insert_item(item)
			return true
	return false

func on_item_drag_started(item: Node2D) -> void:
	for slot in slots:
		if slot.contains_item(item):
			slot.remove_item()
			return


# --- Fire ---
func fire_once() -> bool:
	for slot in slots:
		var ammo := slot.get_loaded_ammo()
		if ammo != null and ammo.is_ammo_new():
			ammo.set_ammo_state(ItemData.AmmoState.EMPTY)
			return true
	return false


# --- Rect helper ---
func _get_item_logic_rect(item: Node2D) -> Rect2:
	if "collision_size" in item:
		var size: Vector2 = item.collision_size
		return Rect2(item.global_position - size * 0.5, size)

	var sprite := item.get_node_or_null("Sprite2D") as Sprite2D
	if sprite and sprite.texture:
		var size2 := sprite.texture.get_size() * sprite.scale
		return Rect2(item.global_position - size2 * 0.5, size2)

	return Rect2(item.global_position, Vector2.ZERO)
