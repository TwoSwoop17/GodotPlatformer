extends Enemy



func stomp(p: Player) -> void:
	dead = true
	_disable_collisions()
	sprite.frame = 2
	p.bounce()
	Game.add_score(100)
	get_tree().create_timer(0.5).timeout.connect(queue_free)
