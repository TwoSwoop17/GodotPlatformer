class_name Enemy
extends CharacterBody2D


const GRAVITY := 900.0

@export var speed := 30.0

var dir := -1.0
var active := false
var dead := false
var anim_clock := 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var body_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	add_to_group("enemies")


func _physics_process(delta: float) -> void:
	if dead:
		return
	var cam := get_viewport().get_camera_2d()
	if not active:
		if cam and global_position.x < cam.get_screen_center_position().x + 144.0:
			active = true
		else:
			return
	_move(delta)
	if global_position.y > 300.0 or (cam and global_position.x < cam.get_screen_center_position().x - 220.0):
		queue_free()
		return
	for body in hitbox.get_overlapping_bodies():
		var p := body as Player
		if p:
			_touch_player(p)
	_animate(delta)


func _move(delta: float) -> void:
	velocity.x = dir * speed
	velocity.y = minf(velocity.y + GRAVITY * delta, 400.0)
	move_and_slide()
	if is_on_wall():
		dir = -dir


func _animate(delta: float) -> void:
	anim_clock += delta
	sprite.frame = int(anim_clock * 5.0) % 2
	sprite.flip_h = dir > 0.0


func _is_stomp(p: Player) -> bool:
	return p.velocity.y > 0.0 and p.global_position.y < global_position.y - 4.0


func _touch_player(p: Player) -> void:
	if p.dead:
		return
	if p.star_timer > 0.0:
		Game.add_score(200)
		die_flip()
	elif _is_stomp(p):
		stomp(p)
	else:
		p.hurt()


func stomp(_p: Player) -> void:
	pass


func die_flip() -> void:
	if dead:
		return
	dead = true
	_disable_collisions()
	sprite.flip_v = true
	z_index = 10
	var t := create_tween()
	t.tween_property(self, "position:y", position.y - 20.0, 0.2).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "position:y", position.y + 240.0, 0.8).set_ease(Tween.EASE_IN)
	t.tween_callback(queue_free)


func _disable_collisions() -> void:
	body_shape.set_deferred("disabled", true)
	hitbox.set_deferred("monitoring", false)
