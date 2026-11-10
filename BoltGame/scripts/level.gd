extends Node2D


const SOURCE_ID := 0
const T_BRICK := Vector2i(2, 0)
const T_QUESTION := Vector2i(3, 0)
const T_USED := Vector2i(4, 0)
const T_INVISIBLE := Vector2i(10, 0)  

const DOOR_X := 3272.0  
const TIME_SPEED := 2.5 

const POWERUP_SCENE := preload("res://scenes/powerup.tscn")
const TILES_TEX := preload("res://assets/tiles.png")
const ITEMS_TEX := preload("res://assets/items.png")


var contents := {
	Vector2i(16, 9): "gear",
	Vector2i(21, 9): "power",
	Vector2i(23, 9): "gear",
	Vector2i(22, 5): "gear",
	Vector2i(78, 9): "power",
	Vector2i(94, 5): "gear",
	Vector2i(94, 9): "multi",
	Vector2i(101, 9): "star",
	Vector2i(106, 9): "gear",
	Vector2i(109, 9): "gear",
	Vector2i(112, 9): "gear",
	Vector2i(109, 5): "power",
	Vector2i(129, 5): "gear",
	Vector2i(130, 5): "gear",
	Vector2i(170, 9): "gear",
}

var hidden_blocks := {
	Vector2i(64, 8): "1up",
}
var multi_hits := {}
var level_done := false

@onready var tiles: TileMapLayer = $Tiles
@onready var player: Player = $Player
@onready var flagpole: Flagpole = $Flagpole
@onready var items: Node2D = $Items


func _ready() -> void:
	Game.time_left = Game.LEVEL_TIME
	player.hit_block.connect(_on_player_hit_block)
	player.reached_door.connect(_on_player_reached_door)
	flagpole.player_reached.connect(_on_flag_reached)


func _process(delta: float) -> void:
	if level_done or player.dead:
		return
	Game.time_left -= delta * TIME_SPEED
	if Game.time_left <= 0.0:
		Game.time_left = 0.0
		player.die()


func _physics_process(_delta: float) -> void:
	_check_hidden_blocks()


func _check_hidden_blocks() -> void:
	if player.dead or hidden_blocks.is_empty() or player.velocity.y >= 0.0:
		return
	var head := player.global_position + Vector2(0, -player.get_height())
	var cell := tiles.local_to_map(tiles.to_local(head))
	if not hidden_blocks.has(cell) or tiles.get_cell_source_id(cell) != -1:
		return
	var cell_bottom := tiles.map_to_local(cell).y + 8.0
	if head.y < cell_bottom - 9.0:
		return  
	var what: String = hidden_blocks[cell]
	hidden_blocks.erase(cell)
	tiles.set_cell(cell, SOURCE_ID, T_USED)
	player.global_position.y = cell_bottom + player.get_height() + 0.5
	player.velocity.y = 40.0
	_spawn_contents(cell, what)
	_bump_anim(cell, T_USED)


func _on_player_hit_block(cell: Vector2i) -> void:
	var atlas := tiles.get_cell_atlas_coords(cell)
	if atlas == T_QUESTION or (atlas == T_BRICK and contents.has(cell)):
		var what: String = contents.get(cell, "gear")
		var final_tile := T_USED
		if what == "multi":
			multi_hits[cell] = multi_hits.get(cell, 0) + 1
			if multi_hits[cell] < 10:
				final_tile = T_BRICK
			else:
				contents.erase(cell)
		else:
			contents.erase(cell)
		_spawn_contents(cell, what)
		_bump_enemies(cell)
		_bump_anim(cell, final_tile)
	elif atlas == T_BRICK:
		_bump_enemies(cell)
		if player.big:
			_break_brick(cell)
		else:
			_bump_anim(cell, T_BRICK)


func _spawn_contents(cell: Vector2i, what: String) -> void:
	match what:
		"gear", "multi":
			_pop_gear(cell)
		"power":
			_spawn_powerup(cell, PowerUp.Kind.BATTERY)
		"star":
			_spawn_powerup(cell, PowerUp.Kind.STAR)
		"1up":
			_spawn_powerup(cell, PowerUp.Kind.CHIP)


func _spawn_powerup(cell: Vector2i, kind: PowerUp.Kind) -> void:
	var pu: PowerUp = POWERUP_SCENE.instantiate()
	pu.kind = kind
	pu.position = tiles.map_to_local(cell)
	items.add_child.call_deferred(pu)


func _pop_gear(cell: Vector2i) -> void:
	Game.add_gear()
	var s := Sprite2D.new()
	s.texture = ITEMS_TEX
	s.hframes = 5
	s.position = tiles.map_to_local(cell) + Vector2(0, -16)
	add_child(s)
	var t := s.create_tween()
	t.tween_property(s, "position:y", s.position.y - 36.0, 0.25).set_ease(Tween.EASE_OUT)
	t.tween_property(s, "position:y", s.position.y - 12.0, 0.2).set_ease(Tween.EASE_IN)
	t.tween_callback(s.queue_free)



func _bump_anim(cell: Vector2i, final_tile: Vector2i) -> void:
	tiles.set_cell(cell, SOURCE_ID, T_INVISIBLE)
	var s := Sprite2D.new()
	s.texture = TILES_TEX
	s.region_enabled = true
	s.region_rect = Rect2(final_tile.x * 16, final_tile.y * 16, 16, 16)
	s.position = tiles.map_to_local(cell)
	add_child(s)
	var t := s.create_tween()
	t.tween_property(s, "position:y", s.position.y - 6.0, 0.08)
	t.tween_property(s, "position:y", s.position.y, 0.08)
	await t.finished
	tiles.set_cell(cell, SOURCE_ID, final_tile)
	s.queue_free()


func _break_brick(cell: Vector2i) -> void:
	tiles.erase_cell(cell)
	Game.add_score(50)
	var center := tiles.map_to_local(cell)
	var dirs: Array[Vector2] = [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 0), Vector2(1, 0)]
	for i in dirs.size():
		var d := Debris.new()
		d.texture = TILES_TEX
		d.region_enabled = true
		d.region_rect = Rect2(T_BRICK.x * 16 + (i % 2) * 8, floori(i / 2.0) * 8, 8, 8)
		d.position = center + dirs[i] * 4.0
		d.velocity = Vector2(dirs[i].x * 70.0, -320.0 if dirs[i].y < 0.0 else -200.0)
		add_child(d)



func _bump_enemies(cell: Vector2i) -> void:
	var top := tiles.map_to_local(cell) - Vector2(0, 8)
	var area := Rect2(top.x - 12.0, top.y - 12.0, 24.0, 16.0)
	for node in get_tree().get_nodes_in_group("enemies"):
		var e := node as Enemy
		if e and not e.dead and area.has_point(e.global_position):
			Game.add_score(100)
			e.die_flip()


func _on_flag_reached(p: Player) -> void:
	level_done = true
	var height := flagpole.global_position.y - p.global_position.y
	var bonus := 100
	if height > 128.0:
		bonus = 5000
	elif height > 96.0:
		bonus = 2000
	elif height > 64.0:
		bonus = 800
	elif height > 32.0:
		bonus = 400
	Game.add_score(bonus)
	flagpole.lower_flag()
	p.play_flag_sequence(flagpole.global_position.x, flagpole.global_position.y, DOOR_X)


func _on_player_reached_door() -> void:
	Game.time_left = floorf(Game.time_left)
	while Game.time_left > 0.0:
		var step := minf(Game.time_left, 5.0)
		Game.time_left -= step
		Game.add_score(int(step) * 50)
		await get_tree().create_timer(0.02).timeout
	await get_tree().create_timer(1.0).timeout
	Game.goto(Game.ENDING_SCENE)
