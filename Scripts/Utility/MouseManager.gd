extends Node
class_name MouseManager

enum CursorState { DEFAULT, HAND_OPEN, HAND_CLOSED }

@export var default_cursor: Texture2D
@export var hand_open: Texture2D
@export var hand_closed: Texture2D

@export var hotspot_default: Vector2 = Vector2.ZERO
@export var hotspot_open: Vector2 = Vector2.ZERO
@export var hotspot_closed: Vector2 = Vector2.ZERO

var _hover_interactable := false
var _dragging := false
var _current: CursorState = CursorState.DEFAULT


func _ready() -> void:
	_apply()


func set_hover_interactable(active: bool) -> void:
	if _hover_interactable == active:
		return
	_hover_interactable = active
	_apply()


func set_dragging(active: bool) -> void:
	if _dragging == active:
		return
	_dragging = active
	_apply()


func force_default() -> void:
	_hover_interactable = false
	_dragging = false
	_apply()


func _apply() -> void:
	var next := CursorState.DEFAULT
	if _dragging:
		next = CursorState.HAND_CLOSED
	elif _hover_interactable:
		next = CursorState.HAND_OPEN

	if next == _current:
		return
	_current = next

	match _current:
		CursorState.DEFAULT:
			if default_cursor:
				Input.set_custom_mouse_cursor(default_cursor, Input.CURSOR_ARROW, hotspot_default)
			else:
				# fallback: si no seteaste default_cursor, vuelve al de Windows
				Input.set_custom_mouse_cursor(null)

		CursorState.HAND_OPEN:
			if hand_open:
				Input.set_custom_mouse_cursor(hand_open, Input.CURSOR_ARROW, hotspot_open)

		CursorState.HAND_CLOSED:
			if hand_closed:
				Input.set_custom_mouse_cursor(hand_closed, Input.CURSOR_ARROW, hotspot_closed)
