extends Node2D

## Attached to player.tscn
## Handles pawn movement on the board

var is_moving: bool = false
var move_time := 0.25
var input_enabled := true

func move_to(target: Vector2):
	if is_moving:
		return

	is_moving = true

	var tween := get_tree().create_tween()
	tween.tween_property(self, "position", target, move_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween.finished.connect(func():
		is_moving = false)
