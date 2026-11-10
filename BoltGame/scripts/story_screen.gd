extends Node2D


@export var lines: PackedStringArray = []
@export_file("*.tscn") var next_scene := ""
@export var start_new_game := false   
@export var show_score := false       

var line_number := 0

@onready var story_text: Label = $StoryText


func _ready() -> void:
	if show_score:
		lines.append("THE END\nGears: %d    Score: %d" % [Game.gears, Game.score])
	story_text.text = lines[0]


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump") or event.is_action_pressed("ui_accept"):
		line_number += 1
		if line_number < lines.size():
			story_text.text = lines[line_number]
		else:
			if start_new_game:
				Game.new_game()
			Game.goto(next_scene)
