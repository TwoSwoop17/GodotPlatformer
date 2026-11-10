extends CanvasLayer

@onready var lives_label: Label = $LivesLabel
@onready var gear_label: Label = $GearLabel
@onready var score_label: Label = $ScoreLabel
@onready var time_label: Label = $TimeLabel


func _process(_delta: float) -> void:
	lives_label.text = "x %d" % Game.lives
	gear_label.text = "x %02d" % Game.gears
	score_label.text = "SCORE\n%06d" % Game.score
	time_label.text = "TIME\n%03d" % int(ceilf(Game.time_left))
