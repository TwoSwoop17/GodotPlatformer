extends Camera2D


@export var target_path: NodePath
@export var level_width := 3392.0

var target: Node2D


func _ready() -> void:
	target = get_node_or_null(target_path)
	make_current()


func _physics_process(_delta: float) -> void:
	if target and target.visible:
		position.x = clampf(maxf(position.x, target.global_position.x), 128.0, level_width - 128.0)
