class_name Player
extends CharacterBody2D


signal hit_block(cell: Vector2i)
signal reached_door

const WALK_SPEED := 90.0
const RUN_SPEED := 150.0
const GROUND_ACCEL := 500.0
const AIR_ACCEL := 350.0
const FRICTION := 600.0
const GRAVITY := 1100.0
const JUMP_VELOCITY := -420.0
const JUMP_CUT := -140.0
const MAX_FALL := 450.0
const STOMP_BOUNCE := -260.0
const FALL_DEATH_Y := 260.0

const SMALL_TEX := preload("res://assets/player_small.png")
const BIG_TEX := preload("res://assets/player_big.png")

enum Frame { IDLE, WALK1, WALK2, JUMP, DEAD }

var big := false
var dead := false
var controls_enabled := true
var on_pole := false
var auto_walk := false
var door_x := INF
var hurt_timer := 0.0
var star_timer := 0.0
var facing := 1
var anim_clock := 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var small_shape: CollisionShape2D = $SmallShape
@onready var big_shape: CollisionShape2D = $BigShape


func _ready() -> void:
	add_to_group("player")
	_apply_size()


func _physics_process(delta: float) -> void:
	if dead:
		velocity.y += GRAVITY * delta
		position += velocity * delta
		return
	if on_pole:
		return

	var dir := 0.0
	if auto_walk:
		dir = 1.0
	elif controls_enabled:
		dir = Input.get_axis("move_left", "move_right")
	var running := controls_enabled and Input.is_action_pressed("run")
	var max_speed := RUN_SPEED if running else WALK_SPEED
	var accel := GROUND_ACCEL if is_on_floor() else AIR_ACCEL

	if dir != 0.0:
		velocity.x = move_toward(velocity.x, dir * max_speed, accel * delta)
		if is_on_floor():
			facing = 1 if dir > 0.0 else -1
	elif is_on_floor():
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)

	velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL)
	if controls_enabled and is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY - absf(velocity.x) * 0.2
	if Input.is_action_just_released("jump") and velocity.y < JUMP_CUT:
		velocity.y = JUMP_CUT  

	move_and_slide()
	_check_head_bump()
	_keep_on_screen()
	_update_animation(delta)

	if global_position.y > FALL_DEATH_Y:
		die()
	elif auto_walk and global_position.x >= door_x:
		auto_walk = false
		visible = false
		set_physics_process(false)
		reached_door.emit()


func _process(delta: float) -> void:
	if dead:
		return
	if hurt_timer > 0.0:
		hurt_timer -= delta
		sprite.visible = hurt_timer <= 0.0 or int(hurt_timer * 20.0) % 2 == 0
	if star_timer > 0.0:
		star_timer -= delta
		sprite.modulate = Color.from_hsv(fmod(star_timer * 3.0, 1.0), 0.5, 1.0) if star_timer > 0.0 else Color.WHITE


func get_height() -> float:
	return 28.0 if big else 14.0



func _check_head_bump() -> void:
	if not is_on_ceiling():
		return
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		if col.get_normal().y < 0.5:
			continue
		var layer := col.get_collider() as TileMapLayer
		if layer == null:
			continue
		var probe := Vector2(global_position.x, col.get_position().y - 4.0)
		var cell := layer.local_to_map(layer.to_local(probe))
		if layer.get_cell_source_id(cell) == -1:
			cell = layer.local_to_map(layer.to_local(col.get_position() - col.get_normal() * 4.0))
		hit_block.emit(cell)
		velocity.y = maxf(velocity.y, 40.0)
		return



func _keep_on_screen() -> void:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var left := cam.get_screen_center_position().x - 128.0 + 6.0
	if global_position.x < left:
		global_position.x = left
		velocity.x = maxf(velocity.x, 0.0)


func _update_animation(delta: float) -> void:
	sprite.flip_h = facing < 0
	if not is_on_floor():
		sprite.frame = Frame.JUMP
	elif absf(velocity.x) > 5.0:
		anim_clock += delta * absf(velocity.x) / 10.0
		sprite.frame = Frame.WALK1 if int(anim_clock) % 2 == 0 else Frame.WALK2
	else:
		sprite.frame = Frame.IDLE


func set_big(value: bool) -> void:
	big = value
	_apply_size()


func _apply_size() -> void:
	sprite.texture = BIG_TEX if big else SMALL_TEX
	sprite.offset = Vector2(0, -16) if big else Vector2(0, -8)
	small_shape.set_deferred("disabled", big)
	big_shape.set_deferred("disabled", not big)


func grow() -> void:
	Game.add_score(1000)
	if big:
		return
	set_big(true)
	var t := create_tween()
	for i in 3:
		t.tween_property(sprite, "modulate", Color(1.6, 1.6, 1.0), 0.08)
		t.tween_property(sprite, "modulate", Color.WHITE, 0.08)


func start_star() -> void:
	star_timer = 10.0
	Game.add_score(1000)


func bounce() -> void:
	velocity.y = JUMP_VELOCITY * 0.9 if Input.is_action_pressed("jump") else STOMP_BOUNCE


func hurt() -> void:
	if dead or hurt_timer > 0.0 or star_timer > 0.0 or not controls_enabled:
		return
	if big:
		set_big(false)
		hurt_timer = 2.0
	else:
		die()


func die() -> void:
	if dead:
		return
	dead = true
	controls_enabled = false
	star_timer = 0.0
	hurt_timer = 0.0
	sprite.texture = SMALL_TEX
	sprite.offset = Vector2(0, -8)
	sprite.frame = Frame.DEAD
	sprite.flip_h = false
	sprite.visible = true
	sprite.modulate = Color.WHITE
	z_index = 20
	small_shape.set_deferred("disabled", true)
	big_shape.set_deferred("disabled", true)
	# Freeze the world while Bolt does his little death hop.
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	velocity = Vector2.ZERO
	var fell := global_position.y > FALL_DEATH_Y
	set_physics_process(false)
	await get_tree().create_timer(0.5).timeout
	if not fell:
		velocity = Vector2(0, -380)
		set_physics_process(true)
	await get_tree().create_timer(2.5).timeout
	Game.lose_life()



func play_flag_sequence(pole_x: float, base_y: float, p_door_x: float) -> void:
	controls_enabled = false
	on_pole = true
	door_x = p_door_x
	star_timer = 0.0
	hurt_timer = 0.0
	sprite.visible = true
	sprite.modulate = Color.WHITE
	velocity = Vector2.ZERO
	global_position.x = pole_x - 6.0
	facing = 1
	sprite.flip_h = false
	sprite.frame = Frame.JUMP
	var dist := maxf(base_y - global_position.y, 0.0)
	var t := create_tween()
	t.tween_property(self, "global_position:y", base_y, dist / 140.0 + 0.05)
	await t.finished
	await get_tree().create_timer(0.4).timeout
	on_pole = false
	auto_walk = true
