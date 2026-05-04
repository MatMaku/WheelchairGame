extends Node2D

@onready var sprite: Sprite2D = $Sprite2D

@export var heal_sprite: Texture2D
@export var ammo_sprite: Texture2D
@export var shell_sprite: Texture2D
@export var key_sprite: Texture2D

var inventory_system: Node = null
var item_type: int


# =========================
# Data
# =========================
func set_data(data: ItemData):
	item_type = data.type
	global_position = data.position

	update_visual()


func get_data() -> ItemData:
	var data = ItemData.new()
	data.type = item_type
	data.position = global_position
	return data


# =========================
# Visual
# =========================
func update_visual():
	match item_type:
		ItemData.ItemType.HEAL:
			sprite.texture = heal_sprite

		ItemData.ItemType.AMMO:
			sprite.texture = ammo_sprite

		ItemData.ItemType.SHELL:
			sprite.texture = shell_sprite

		ItemData.ItemType.KEY:
			sprite.texture = key_sprite


# =========================
# Mouse
# =========================
func is_mouse_over() -> bool:
	if not sprite or not sprite.texture:
		return false

	var size = sprite.texture.get_size() * sprite.scale

	var rect = Rect2(
		global_position - size * 0.5,
		size
	)

	return rect.has_point(get_viewport().get_mouse_position())
