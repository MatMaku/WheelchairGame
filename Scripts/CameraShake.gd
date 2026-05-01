extends Camera2D

@export var shake_strength := 1.5

func _process(delta):
	var offset = Vector2(
		randf_range(-shake_strength, shake_strength),
		randf_range(-shake_strength, shake_strength)
	)
	self.offset = offset
