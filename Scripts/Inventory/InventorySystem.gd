extends CanvasLayer

@export var max_items := 10
@export var item_scene: PackedScene
@export var initial_items: Array[ItemData] = []

@export var separation_distance := 40.0
@export var separation_speed := 10.0

@onready var items_container: Node = $Root/ItemsContainer
@onready var drag_layer: Node = $Root/DragLayer
@onready var inventory_area: Control = $Root/InventoryArea
@onready var shotgun_ui: Node = $Root/ShotgunUI

var items: Array = []
var current_drag_item: Node2D = null

var target_positions := {}


func _ready():
	spawn_initial_items()


func _process(delta):
	update_separation(delta)


# =========================
# Spawn
# =========================
func spawn_initial_items():
	for data in initial_items:
		if items.size() >= max_items:
			return

		var item = item_scene.instantiate()
		items_container.add_child(item)

		item.inventory_system = self
		item.set_data(data)

		items.append(item)
		target_positions[item] = item.global_position


# =========================
# Input
# =========================
func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			try_start_drag()
		else:
			end_drag()

	if event is InputEventMouseMotion and current_drag_item:
		update_drag()


func get_mouse_pos() -> Vector2:
	return get_viewport().get_mouse_position()


func try_start_drag():
	if current_drag_item:
		return

	for i in range(items_container.get_child_count() - 1, -1, -1):
		var item = items_container.get_child(i)

		if item.has_method("is_mouse_over") and item.is_mouse_over():
			start_drag(item)
			break


# =========================
# Drag
# =========================
func start_drag(item: Node2D):
	current_drag_item = item

	var offset = item.global_position - get_mouse_pos()
	item.set_meta("drag_offset", offset)

	item.reparent(drag_layer)
	item.z_index = 1000


func update_drag():
	if not current_drag_item:
		return

	var offset = current_drag_item.get_meta("drag_offset")
	current_drag_item.global_position = get_mouse_pos() + offset

	if shotgun_ui and shotgun_ui.has_method("is_item_in_interaction_area"):
		var inside = shotgun_ui.is_item_in_interaction_area(current_drag_item)

		if current_drag_item.has_method("set_in_shotgun_area"):
			current_drag_item.set_in_shotgun_area(inside)

func end_drag():
	if not current_drag_item:
		return

	var item = current_drag_item
	current_drag_item = null

	if item.has_method("set_in_shotgun_area"):
		item.set_in_shotgun_area(false)

	if shotgun_ui and shotgun_ui.has_method("try_insert_item"):
		if shotgun_ui.try_insert_item(item):
			items.erase(item)
			target_positions.erase(item)

			item.reparent(shotgun_ui)
			item.z_index = 0
			return

		if shotgun_ui.has_method("is_item_in_interaction_area"):
			if shotgun_ui.is_item_in_interaction_area(item):
				item.reparent(items_container)
				items_container.move_child(item, items_container.get_child_count() - 1)

				calculate_separation_targets()
				target_positions[item] = clamp_item_inside(item)

				item.z_index = 0
				return

	item.reparent(items_container)
	items_container.move_child(item, items_container.get_child_count() - 1)

	if is_item_fully_outside(item):
		drop_outside(item)
	else:
		calculate_separation_targets()
		target_positions[item] = clamp_item_inside(item)

	item.z_index = 0

# =========================
# Drop
# =========================
func drop_outside(item):
	if item in items:
		items.erase(item)

	target_positions.erase(item)
	item.queue_free()


# =========================
# Separación
# =========================
func calculate_separation_targets():
	for item in items:
		target_positions[item] = item.global_position

	for i in range(items.size()):
		var a = items[i]

		for j in range(i + 1, items.size()):
			var b = items[j]

			var dir = target_positions[a] - target_positions[b]
			var dist = dir.length()

			if dist == 0:
				dir = Vector2.RIGHT
				dist = 0.01

			if dist < separation_distance:
				var push = dir.normalized() * (separation_distance - dist)

				target_positions[a] += push * 0.5
				target_positions[b] -= push * 0.5


func update_separation(delta):
	for item in items:
		if item == current_drag_item:
			continue

		if not target_positions.has(item):
			continue

		var target = target_positions[item]

		if not is_item_fully_outside(item):
			target = clamp_item_inside_target(item, target)

		item.global_position = item.global_position.lerp(target, separation_speed * delta)


# =========================
# RECT PARA INTERACCIONES
# =========================
func get_item_logic_rect(item: Node2D) -> Rect2:
	if "collision_size" in item:
		var size: Vector2 = item.collision_size
		return Rect2(item.global_position - size * 0.5, size)

	return Rect2(item.global_position, Vector2.ZERO)


# =========================
# RECT VISUAL
# =========================
func get_item_visual_rect(item: Node2D) -> Rect2:
	var sprite: Sprite2D = item.get_node_or_null("Sprite2D")

	if sprite and sprite.texture:
		var size = sprite.texture.get_size() * sprite.scale
		return Rect2(item.global_position - size * 0.5, size)

	return Rect2(item.global_position, Vector2.ZERO)


func is_item_fully_outside(item: Node2D) -> bool:
	return not inventory_area.get_global_rect().intersects(get_item_visual_rect(item))


func clamp_item_inside(item: Node2D) -> Vector2:
	var rect = get_item_visual_rect(item)
	var area = inventory_area.get_global_rect()

	var half = rect.size * 0.5
	var pos = item.global_position

	pos.x = clamp(pos.x, area.position.x + half.x, area.end.x - half.x)
	pos.y = clamp(pos.y, area.position.y + half.y, area.end.y - half.y)

	return pos


func clamp_item_inside_target(item: Node2D, target: Vector2) -> Vector2:
	var rect = get_item_visual_rect(item)
	var area = inventory_area.get_global_rect()

	var half = rect.size * 0.5
	var pos = target

	pos.x = clamp(pos.x, area.position.x + half.x, area.end.x - half.x)
	pos.y = clamp(pos.y, area.position.y + half.y, area.end.y - half.y)

	return pos


# =========================
# Utils
# =========================
func reset_drag_offset(item):
	if current_drag_item == item:
		item.set_meta("drag_offset", Vector2.ZERO)
