class_name Flagpole
extends Area2D


signal player_reached(player: Player)

var triggered := false

@onready var flag: Sprite2D = $Flag


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	var p := body as Player
	if triggered or p == null or p.dead:
		return
	triggered = true
	player_reached.emit(p)


func lower_flag() -> void:
	var t := create_tween()
	t.tween_property(flag, "position:y", -20.0, 1.0)
