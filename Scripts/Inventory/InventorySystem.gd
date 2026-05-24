extends CanvasLayer
class_name InventorySystem

@export var max_items: int = 10
@export var item_scene: PackedScene
@export var initial_items: Array[ItemData] = []

@export var separation_distance: float = 40.0
@export var separation_speed: float = 10.0

@onready var items_container: Node = $Root/ItemsContainer
@onready var inventory_area: Control = $Root/InventoryArea
@onready var shotgun_ui: ShotgunUI = $Root/ShotgunUI
@onready var drag_controller: DragController = $Root/DragController

var items: Array[Node2D] = []
var target_positions: Dictionary = {} # Node2D -> Vector2
var dragged_item: Node2D = null


# --- Lifecycle ---
func _ready() -> void:
	_spawn_initial_items()


func _process(delta: float) -> void:
	_update_separation(delta)


# --- Spawn / Register ---
func _spawn_initial_items() -> void:
	for data in initial_items:
		if items.size() >= max_items:
			break

		var item := item_scene.instantiate() as Node2D
		items_container.add_child(item)

		# Compat: tu item tiene inventory_system y set_data()
		if "inventory_system" in item:
			item.inventory_system = self
		if item.has_method("set_data"):
			item.set_data(data)

		items.append(item)
		target_positions[item] = item.global_position

	_calculate_separation_targets()


# --- Drag API ---
func set_dragged_item(item: Node2D) -> void:
	dragged_item = item


func pick_item_at_mouse() -> Node2D:
	for i in range(items_container.get_child_count() - 1, -1, -1):
		var item := items_container.get_child(i)
		if item is Node2D and item.has_method("is_mouse_over") and item.is_mouse_over():
			return item
	return null


func on_item_moved_to_shotgun(item: Node2D) -> void:
	items.erase(item)
	target_positions.erase(item)


func on_item_dropped_inside(item: Node2D) -> void:
	if not items.has(item):
		items.append(item)

	target_positions[item] = clamp_item_inside(item)
	_calculate_separation_targets([item])


func on_item_drop_finished(item: Node2D) -> void:
	if is_item_fully_outside(item):
		drop_outside(item)
		return

	if not items.has(item):
		items.append(item)

	target_positions[item] = clamp_item_inside(item)
	_calculate_separation_targets([item])


func reset_drag_offset(item: Node2D) -> void:
	if is_instance_valid(drag_controller):
		drag_controller.reset_drag_offset_for(item)


# --- Drop ---
func drop_outside(item: Node2D) -> void:
	items.erase(item)
	target_positions.erase(item)
	item.queue_free()


# --- Separation / Layout ---
func _calculate_separation_targets(preserve: Array[Node2D] = []) -> void:
	var preserve_set: Dictionary = {}
	for p in preserve:
		preserve_set[p] = true

	for item in items:
		if preserve_set.has(item) and target_positions.has(item):
			continue
		target_positions[item] = item.global_position

	for i in range(items.size()):
		var a := items[i]
		for j in range(i + 1, items.size()):
			var b := items[j]

			var dir: Vector2 = target_positions[a] - target_positions[b]
			var dist := dir.length()

			if dist <= 0.0001:
				dir = Vector2.RIGHT
				dist = 0.01

			if dist < separation_distance:
				var push := dir.normalized() * (separation_distance - dist)
				target_positions[a] += push * 0.5
				target_positions[b] -= push * 0.5


func _update_separation(delta: float) -> void:
	for item in items:
		if item == dragged_item:
			continue

		var target: Variant = target_positions.get(item, null)
		if target == null:
			continue

		var t := target as Vector2
		if not is_item_fully_outside(item):
			t = clamp_item_inside_target(item, t)

		item.global_position = item.global_position.lerp(t, separation_speed * delta)


# --- Rects ---
func get_item_logic_rect(item: Node2D) -> Rect2:
	return _get_item_logic_rect(item)


func _get_item_logic_rect(item: Node2D) -> Rect2:
	if "collision_size" in item:
		var size: Vector2 = item.collision_size
		return Rect2(item.global_position - size * 0.5, size)
	return _get_item_visual_rect(item)


func _get_item_visual_rect(item: Node2D) -> Rect2:
	var sprite := item.get_node_or_null("Sprite2D") as Sprite2D
	if sprite and sprite.texture:
		var size := sprite.texture.get_size() * sprite.scale
		return Rect2(item.global_position - size * 0.5, size)
	return Rect2(item.global_position, Vector2.ZERO)


func is_item_fully_outside(item: Node2D) -> bool:
	return not inventory_area.get_global_rect().intersects(_get_item_visual_rect(item))


func clamp_item_inside(item: Node2D) -> Vector2:
	return clamp_item_inside_target(item, item.global_position)


func clamp_item_inside_target(item: Node2D, target: Vector2) -> Vector2:
	var rect := _get_item_visual_rect(item)
	var area := inventory_area.get_global_rect()

	var half := rect.size * 0.5
	var pos := target

	pos.x = clamp(pos.x, area.position.x + half.x, area.end.x - half.x)
	pos.y = clamp(pos.y, area.position.y + half.y, area.end.y - half.y)

	return pos
