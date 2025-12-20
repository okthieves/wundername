extends Node2D

@onready var spawn := $"Spawn_Default"
@onready var player := $"SoulForm" # your soulform node


func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		GameManager.hud.exit_sidescroll()

func _ready():
	player.global_position = spawn.global_position
	player.velocity = Vector2.ZERO
