extends Sprite2D

@export var duration := 0.05
@export var scale_variation := 0.2

var time := 0.0
var active := false


func trigger():
	active = true
	time = 0.0

	visible = true

	# 🔥 variación
	var s = 1.0 + randf_range(-scale_variation, scale_variation)
	scale = Vector2(s, s)

	modulate.a = 1.0


func _process(delta):
	if not active:
		return

	time += delta

	var t = time / duration
	modulate.a = 1.0 - t

	if time >= duration:
		visible = false
		active = false
