extends Node
class_name ShotgunFireSimulator

@export var shotgun_ui: ShotgunUI
@export var shoot_button: Button
@export var loaded_label: Label

var _last_count := -1

func _ready() -> void:
	if shoot_button:
		shoot_button.pressed.connect(_on_shoot_pressed)
	_refresh()

func _process(_delta: float) -> void:
	_refresh()

func _refresh() -> void:
	if not shotgun_ui or not shoot_button:
		return

	var count := shotgun_ui.get_loaded_new_ammo_count()
	if count == _last_count:
		return
	_last_count = count

	shoot_button.disabled = count <= 0
	if loaded_label:
		loaded_label.text = str(count)

func _on_shoot_pressed() -> void:
	if shotgun_ui and shotgun_ui.fire_once():
		_refresh()
