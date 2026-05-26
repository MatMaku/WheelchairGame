extends Control
class_name ShotgunSlot

@export var accepted_type: ItemData.ItemType = ItemData.ItemType.AMMO

var current_item: Node2D = null


# --- State ---
func is_empty() -> bool:
	return current_item == null

func contains_item(item: Node2D) -> bool:
	return current_item == item

func get_loaded_ammo() -> DraggableItem:
	return current_item as DraggableItem

func has_new_ammo_loaded() -> bool:
	var a := get_loaded_ammo()
	return a != null and a.is_ammo_new()


# --- Rules ---
func can_accept(item: Node2D) -> bool:
	if not is_empty():
		return false
	if not ("item_type" in item) or item.item_type != accepted_type:
		return false

	var di := item as DraggableItem
	if di != null and di.item_type == ItemData.ItemType.AMMO:
		return di.is_ammo_new() # NO aceptar EMPTY

	return true


# --- Actions ---
func insert_item(item: Node2D) -> void:
	current_item = item

	var rect := get_global_rect()
	item.global_position = rect.position + rect.size * 0.5

	if item.has_method("set_in_slot"):
		item.set_in_slot(true)

func remove_item() -> Node2D:
	var item := current_item
	current_item = null

	if item and item.has_method("set_in_slot"):
		item.set_in_slot(false)

	return item


# --- Overlap ---
func is_item_overlapping(item: Node2D) -> bool:
	return get_global_rect().intersects(_get_item_logic_rect(item))

func _get_item_logic_rect(item: Node2D) -> Rect2:
	if "collision_size" in item:
		var size: Vector2 = item.collision_size
		return Rect2(item.global_position - size * 0.5, size)

	var sprite := item.get_node_or_null("Sprite2D") as Sprite2D
	if sprite and sprite.texture:
		var size2 := sprite.texture.get_size() * sprite.scale
		return Rect2(item.global_position - size2 * 0.5, size2)

	return Rect2(item.global_position, Vector2.ZERO)
