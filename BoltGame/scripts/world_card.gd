extends Control

@onready var title: Label = $Title
@onready var lives_row: Control = $LivesRow
@onready var lives_label: Label = $LivesRow/LivesLabel


func _ready() -> void:
	if Game.lives <= 0:
		title.text = "GAME OVER"
		lives_row.visible = false
		await get_tree().create_timer(3.0).timeout
		Game.goto(Game.INTRO_SCENE)
	else:
		title.text = "WORLD 1-1"
		lives_label.text = "x  %d" % Game.lives
		await get_tree().create_timer(2.0).timeout
		Game.goto(Game.LEVEL_SCENE)
