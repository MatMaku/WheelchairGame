extends Node
class_name InventoryManager

@export var inventory_scene: PackedScene
@export var ui_parent: Node

var inventory: InventorySystem
var is_open := false

var _player_input: PlayerInput
var _shooting_manager: ShootingManager


func _ready() -> void:
	_ensure_inventory()
	_resolve_player_refs()
	_apply_state()


func _process(_delta: float) -> void:
	# por si el player se instancia después
	if _player_input == null or _shooting_manager == null:
		_resolve_player_refs()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_inventory") and not event.echo:
		is_open = not is_open
		_apply_state()


func _ensure_inventory() -> void:
	if inventory:
		return
	if not inventory_scene or not ui_parent:
		return

	inventory = inventory_scene.instantiate() as InventorySystem
	ui_parent.add_child(inventory)
	inventory.visible = false


func _resolve_player_refs() -> void:
	if _player_input == null:
		_player_input = get_tree().get_first_node_in_group("player_input") as PlayerInput
	if _shooting_manager == null:
		_shooting_manager = get_tree().get_first_node_in_group("shooting_manager") as ShootingManager


func _apply_state() -> void:
	# Inventario UI
	if inventory:
		inventory.visible = is_open
		inventory.set_process(is_open)

		if inventory.drag_controller:
			inventory.drag_controller.set_process_unhandled_input(is_open)

	# Bloqueo de interacción (sin pausar el juego)
	if _player_input:
		_player_input.set_enabled(not is_open)

	if _shooting_manager:
		_shooting_manager.set_enabled(not is_open)
