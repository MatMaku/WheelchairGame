extends Node2D

@export var textures: Array[Texture2D]

@export var count_min := 3
@export var count_max := 6

@export var spawn_radius := 6.0

@export var base_lifetime := 0.6
@export var lifetime_variation := 0.3

@export var expansion_speed := 1.5

@export var velocity_min := 10.0
@export var velocity_max := 40.0

@export var spread := 0.6


# 🔹 lista de partículas internas
var particles: Array = []


func setup(origin: Vector2, base_dir: Vector2):
	global_position = origin

	var count = randi_range(count_min, count_max)

	for i in range(count):
		var sprite := Sprite2D.new()
		add_child(sprite)

		# 🔹 textura random
		if textures.size() > 0:
			sprite.texture = textures.pick_random()

		# 🔹 posición local random (círculo)
		var offset = Vector2(
			randf_range(-1, 1),
			randf_range(-1, 1)
		)

		if offset.length() > 0:
			offset = offset.normalized()

		offset *= randf_range(0, spawn_radius)
		sprite.position = offset

		# 🔹 escala random
		var s = randf_range(0.4, 0.6)
		sprite.scale = Vector2(s, s)

		# 🔹 alpha random
		sprite.modulate.a = randf_range(0.5, 0.9)

		# 🔹 rotación random
		sprite.rotation = randf_range(0, TAU)

		# 🔹 lifetime random
		var lifetime = base_lifetime + randf_range(-lifetime_variation, lifetime_variation)
		lifetime = max(0.1, lifetime)

		# 🔹 dirección con dispersión
		var dir = base_dir.rotated(randf_range(-spread, spread))

		# 🔹 velocidad random
		var velocity = dir * randf_range(velocity_min, velocity_max)

		# 🔹 guardamos data
		particles.append({
			"sprite": sprite,
			"time": 0.0,
			"lifetime": lifetime,
			"velocity": velocity
		})


func _process(delta):
	# 🔹 iterar partículas
	for p in particles:
		p.time += delta

		var sprite: Sprite2D = p.sprite

		# movimiento
		sprite.position += p.velocity * delta

		# expansión
		sprite.scale += Vector2.ONE * expansion_speed * delta

		# fade
		var t = p.time / p.lifetime
		sprite.modulate.a = 1.0 - t

	# 🔹 limpiar partículas muertas
	particles = particles.filter(func(p):
		if p.time >= p.lifetime:
			p.sprite.queue_free()
			return false
		return true
	)

	# 🔹 si no queda nada → borrar nodo
	if particles.size() == 0:
		queue_free()
