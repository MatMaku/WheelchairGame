extends Node
class_name InventoryManager

@export var inventory: InventorySystem
@export var inventory_group := "inventory_system"

@export var block_player_input := false # false = el player puede moverse
@export var block_shooting := true

var is_open := false
var _player_input: PlayerInput
var _shooting_manager: ShootingManager


func _ready() -> void:
	_resolve_inventory()
	_resolve_player_refs()
	_set_open(false)


func _process(_delta: float) -> void:
	if _player_input == null or _shooting_manager == null:
		_resolve_player_refs()
	if inventory == null:
		_resolve_inventory()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_inventory") and not event.echo:
		# evita que TAB lo use la UI (focus navigation)
		get_viewport().set_input_as_handled()
		_set_open(not is_open)


func _resolve_inventory() -> void:
	if inventory != null:
		return
	inventory = get_tree().get_first_node_in_group(inventory_group) as InventorySystem


func _resolve_player_refs() -> void:
	if _player_input == null:
		_player_input = get_tree().get_first_node_in_group("player_input") as PlayerInput
	if _shooting_manager == null:
		_shooting_manager = get_tree().get_first_node_in_group("shooting_manager") as ShootingManager


func _set_open(open: bool) -> void:
	is_open = open

	if inventory:
		inventory.visible = is_open
		inventory.set_process(is_open)

		if inventory.drag_controller:
			inventory.drag_controller.set_process_unhandled_input(is_open)

	if block_player_input and _player_input:
		_player_input.set_enabled(not is_open)

	if block_shooting and _shooting_manager:
		_shooting_manager.set_enabled(not is_open)
