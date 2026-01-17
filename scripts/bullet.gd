class_name Bullet extends Area2D

@export var speed := 7.0

var direction:Vector2

func _physics_process(delta: float) -> void:
	global_position += direction * speed * 60 * delta
