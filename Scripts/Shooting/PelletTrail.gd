extends Line2D

@export var base_lifetime := 2
@export var lifetime_variation := 1

@export var segments := 10
@export var distortion_strength := 8

var lifetime := 2
var time := 0.0


func setup(start: Vector2, end: Vector2):
	# 🔥 lifetime random
	lifetime = base_lifetime + randf_range(-lifetime_variation, lifetime_variation)
	lifetime = max(0.01, lifetime)  # evitar valores negativos o 0

	clear_points()

	var dir = (end - start).normalized()
	var normal = Vector2(-dir.y, dir.x)

	for i in range(segments + 1):
		var t = float(i) / segments
		var base_point = start.lerp(end, t)

		if i == 0 or i == segments:
			add_point(base_point)
			continue

		var offset = randf_range(-distortion_strength, distortion_strength)

		var falloff = sin(t * PI)
		offset *= falloff

		var distorted = base_point + normal * offset
		add_point(distorted)


func _process(delta):
	time += delta

	var t = time / lifetime
	modulate.a = 1.0 - t

	if time >= lifetime:
		queue_free()
