extends Resource
class_name ItemData

enum ItemType { HEAL, AMMO, KEY }
enum AmmoState { NEW, EMPTY }

@export var type: ItemType = ItemType.AMMO
@export var position: Vector2 = Vector2.ZERO
@export var ammo_state: AmmoState = AmmoState.NEW
