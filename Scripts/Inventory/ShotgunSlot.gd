extends Control

@export var accepted_type := ItemData.ItemType.AMMO

var current_item: Node2D = null


func is_empty() -> bool:
	return current_item == null


func can_accept(item: Node2D) -> bool:
	return is_empty() and item.item_type == accepted_type


func insert_item(item: Node2D):
	current_item = item

	var rect = get_global_rect()
	var center = rect.position + rect.size * 0.5

	item.global_position = center

	if item.has_method("set_in_slot"):
		item.set_in_slot(true)


func is_item_overlapping(item: Node2D) -> bool:
	if item.inventory_system:
		var item_rect = item.inventory_system.get_item_logic_rect(item)
		return get_global_rect().intersects(item_rect)

	return false
