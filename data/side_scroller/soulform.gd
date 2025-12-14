extends CharacterBody2D

## Attached to soulform.tscn
## Handles side scroll character movement


## --------------------------
## MOVEMENT SETTINGS
## --------------------------
var speed := 120.0
var jump_force := 260.0
var gravity := 600.0

func _physics_process(delta):
	apply_gravity(delta)
	handle_horizontal_input()
	handle_jump(delta)

	move_and_slide()

func apply_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		# Small snap to keep grounded
		velocity.y = max(velocity.y, 0)

func handle_horizontal_input():
	var input_dir := Input.get_axis("move_left", "move_right")
	velocity.x = input_dir * speed

func handle_jump(delta):
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = -jump_force
