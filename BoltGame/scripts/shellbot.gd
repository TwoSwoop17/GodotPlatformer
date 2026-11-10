extends Enemy

enum State { WALK, SHELL, SLIDE }

const WALK_SPEED := 30.0
const SLIDE_SPEED := 200.0
const MASK_NORMAL := 1 | 4  
const MASK_SLIDING := 1    

var state := State.WALK
var grace := 0.0  #

func _move(delta: float) -> void:
	grace = maxf(grace - delta, 0.0)
	match state:
		State.WALK:
			speed = WALK_SPEED
		State.SHELL:
			speed = 0.0
		State.SLIDE:
			speed = SLIDE_SPEED
	super._move(delta)
	if state == State.SLIDE:
		for body in hitbox.get_overlapping_bodies():
			var other := body as Enemy
			if other and other != self and not other.dead:
				other.die_flip()
				Game.add_score(200)


func _animate(delta: float) -> void:
	if state == State.WALK:
		super._animate(delta)
	else:
		sprite.frame = 2


func _touch_player(p: Player) -> void:
	if p.dead:
		return
	if p.star_timer > 0.0:
		Game.add_score(200)
		die_flip()
		return
	if grace > 0.0:
		return
	match state:
		State.WALK:
			if _is_stomp(p):
				_set_state(State.SHELL)
				p.bounce()
				Game.add_score(100)
			else:
				p.hurt()
		State.SHELL:
			dir = 1.0 if global_position.x >= p.global_position.x else -1.0
			_set_state(State.SLIDE)
			Game.add_score(400)
			if _is_stomp(p):
				p.bounce()
		State.SLIDE:
			if _is_stomp(p):
				_set_state(State.SHELL)
				p.bounce()
			else:
				p.hurt()


func _set_state(new_state: State) -> void:
	state = new_state
	grace = 0.25
	collision_mask = MASK_SLIDING if state == State.SLIDE else MASK_NORMAL
