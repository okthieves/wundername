## Side-scrolling player controller used inside SubViewport scenes.
## Attached to `soulform.tscn` and responsible for basic platformer movement.
extends CharacterBody2D

## --------------------------
## MOVEMENT SETTINGS
## --------------------------

## Horizontal movement speed in pixels per second.
## Affects left/right input responsiveness.
var speed := 120.0

## Upward impulse applied when the player jumps.
## Higher values result in taller jumps.
var jump_force := 260.0

## Downward acceleration applied while airborne.
## Simulates gravity for the side-scrolling scene.
var gravity := 600.0


## Handles physics-based movement every physics frame.
## Movement is disabled while the Wunderpal menu is open.
## @param delta Time elapsed since the last physics frame.
func _physics_process(delta):
	if GameManager.state == GameManager.GameState.MENU_OPEN:
		velocity = Vector2.ZERO
		return

	apply_gravity(delta)
	handle_horizontal_input()
	handle_jump(delta)

	move_and_slide()


## Applies gravity to the character when not grounded.
## Ensures the player snaps cleanly to the floor when landing.
## @param delta Time elapsed since the last physics frame.
func apply_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		# Prevents downward accumulation when grounded
		velocity.y = max(velocity.y, 0)


## Reads horizontal input and applies it to the character velocity.
## Uses input actions "move_left" and "move_right".
func handle_horizontal_input():
	var input_dir := Input.get_axis("move_left", "move_right")
	velocity.x = input_dir * speed


## Handles jump input when the character is grounded.
## Uses the "jump" input action.
## @param delta Time elapsed since the last physics frame.
func handle_jump(delta):
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = -jump_force
