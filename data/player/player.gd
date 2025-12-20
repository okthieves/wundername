## Board pawn controller.
## Attached to `player.tscn` and responsible for smooth movement between board slots.
## Used during the board-game phase of gameplay.
extends Node2D


## True while the pawn is currently animating toward a target position.
## Prevents overlapping or interrupted movement commands.
var is_moving: bool = false

## Duration (in seconds) of a single board movement tween.
## Controls how fast the pawn slides between slots.
var move_time := 0.25

## Whether player input is currently allowed.
## Can be disabled during animations, menus, or cutscenes.
var input_enabled := true


## Moves the pawn smoothly to a target position on the board.
## Uses a tween for eased motion and blocks additional movement until complete.
## @param target The world position to move the pawn to.
func move_to(target: Vector2):
	if is_moving:
		return

	is_moving = true

	var tween := get_tree().create_tween()
	tween.tween_property(
		self,
		"position",
		target,
		move_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween.finished.connect(func():
		is_moving = false)
