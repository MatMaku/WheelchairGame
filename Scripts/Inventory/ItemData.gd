extends Resource
class_name ItemData

enum ItemType {
	HEAL,
	AMMO,
	SHELL,
	KEY
}

@export var type: ItemType = ItemType.AMMO
@export var position: Vector2 = Vector2.ZERO
