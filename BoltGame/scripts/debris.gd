class_name Debris
extends Sprite2D

var velocity := Vector2.ZERO
var life := 1.2


func _physics_process(delta: float) -> void:
	velocity.y += 900.0 * delta
	position += velocity * delta
	rotation += delta * 10.0
	life -= delta
	if life <= 0.0:
		queue_free()
