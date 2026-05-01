extends Node2D

@export var player: CharacterBody2D

@export var left_wheels: Array[Sprite2D]
@export var right_wheels: Array[Sprite2D]

@export var speed_factor := 0.005
@export var turn_influence := 50.0

var left_offset := 0.0
var right_offset := 0.0


func _process(delta):
	if player == null:
		return

	if not player.has_method("get_forward_speed"):
		return

	var forward_speed = player.get_forward_speed()
	var angular = player.get_angular_velocity()

	left_offset += (forward_speed - angular * turn_influence) * speed_factor * delta
	right_offset += (forward_speed + angular * turn_influence) * speed_factor * delta

	for w in left_wheels:
		if w and w.material:
			w.material.set_shader_parameter("offset", left_offset)

	for w in right_wheels:
		if w and w.material:
			w.material.set_shader_parameter("offset", right_offset)
