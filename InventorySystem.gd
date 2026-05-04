extends CanvasLayer

@export var max_items := 10
@export var item_scene: PackedScene
@export var initial_items: Array[ItemData] = []

@export var separation_distance := 40.0
@export var separation_speed := 10.0


@onready var items_container: Node2D = $Root/ItemsContainer
@onready var drag_layer: Node2D = $Root/DragLayer
@onready var inventory_area: Control = $Root/InventoryArea

var items: Array = []
var current_drag_item: Node2D = null

# 🔹 posiciones objetivo para separación suave
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


func end_drag():
	if not current_drag_item:
		return

	var item = current_drag_item
	current_drag_item = null

	var mouse_pos = get_mouse_pos()

	if inventory_area.get_global_rect().has_point(mouse_pos):
		item.reparent(items_container)

		# 🔥 NO tocamos la posición → queda donde estaba

		items_container.move_child(item, items_container.get_child_count() - 1)

		# recalcular separación con targets
		calculate_separation_targets()

	else:
		drop_outside(item)

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
# Separación suave
# =========================
func calculate_separation_targets():
	# iniciar con posiciones actuales
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
		item.global_position = item.global_position.lerp(target, separation_speed * delta)
