class_name PowerUp
extends CharacterBody2D

enum Kind { BATTERY, CHIP, STAR }

const GRAVITY := 900.0
const FRAMES := { Kind.BATTERY: 1, Kind.CHIP: 2, Kind.STAR: 3 }

@export var kind: Kind = Kind.BATTERY

var dir := 1.0
var emerging := true

@onready var sprite: Sprite2D = $Sprite2D
@onready var pickup: Area2D = $Pickup


func _ready() -> void:
	sprite.frame = FRAMES[kind]
	z_index = -1  
	var t := create_tween()
	t.tween_property(self, "position:y", position.y - 16.0, 0.6)
	await t.finished
	z_index = 0
	emerging = false


func _physics_process(delta: float) -> void:
	for body in pickup.get_overlapping_bodies():
		var p := body as Player
		if p and not p.dead:
			_collect(p)
			return
	if emerging:
		return
	velocity.x = dir * (70.0 if kind == Kind.STAR else 55.0)
	velocity.y = minf(velocity.y + GRAVITY * delta, 400.0)
	move_and_slide()
	if is_on_wall():
		dir = -dir
	if kind == Kind.STAR and is_on_floor():
		velocity.y = -300.0
	if global_position.y > 300.0:
		queue_free()


func _collect(p: Player) -> void:
	match kind:
		Kind.BATTERY:
			p.grow()
		Kind.CHIP:
			Game.add_life()
		Kind.STAR:
			p.start_star()
	queue_free()
