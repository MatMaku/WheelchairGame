extends Node2D

@onready var interaction_area: Control = $InteractionArea
var slots: Array = []


func _ready():
	for child in get_children():
		if child.has_method("can_accept"):
			slots.append(child)


func is_item_in_interaction_area(item: Node2D) -> bool:
	if item.inventory_system:
		var item_rect = item.inventory_system.get_item_logic_rect(item)
		return interaction_area.get_global_rect().intersects(item_rect)

	return false


func try_insert_item(item: Node2D) -> bool:
	for slot in slots:
		if slot.can_accept(item) and slot.is_item_overlapping(item):
			slot.insert_item(item)
			return true

	return false
