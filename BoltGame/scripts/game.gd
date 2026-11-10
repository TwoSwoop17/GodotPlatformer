extends Node

const START_LIVES := 3
const LEVEL_TIME := 400.0
const INTRO_SCENE := "res://scenes/intro.tscn"
const WORLD_CARD_SCENE := "res://scenes/world_card.tscn"
const LEVEL_SCENE := "res://scenes/level_1_1.tscn"
const ENDING_SCENE := "res://scenes/ending.tscn"

var lives := START_LIVES
var gears := 0
var score := 0
var time_left := LEVEL_TIME


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_register_inputs()


func new_game() -> void:
	lives = START_LIVES
	gears = 0
	score = 0
	time_left = LEVEL_TIME


func add_gear() -> void:
	gears += 1
	score += 200
	if gears >= 100:
		gears -= 100
		add_life()


func add_score(points: int) -> void:
	score += points


func add_life() -> void:
	lives += 1


func lose_life() -> void:
	lives -= 1
	goto(WORLD_CARD_SCENE)


func goto(path: String) -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(path)



func _register_inputs() -> void:
	_bind("move_left", [KEY_LEFT, KEY_A], [JOY_BUTTON_DPAD_LEFT])
	_bind("move_right", [KEY_RIGHT, KEY_D], [JOY_BUTTON_DPAD_RIGHT])
	_bind("jump", [KEY_SPACE, KEY_Z, KEY_UP, KEY_W], [JOY_BUTTON_A])
	_bind("run", [KEY_SHIFT, KEY_X], [JOY_BUTTON_X])


func _bind(action: String, keys: Array, buttons: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for key in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = key
		InputMap.action_add_event(action, ev)
	for button in buttons:
		var jev := InputEventJoypadButton.new()
		jev.button_index = button
		InputMap.action_add_event(action, jev)
