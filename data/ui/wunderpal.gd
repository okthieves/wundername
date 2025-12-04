extends SubViewport

func _ready():
	# Load the test side-scroller scene
	var test_scene = load("res://scenes/world/test_scene.tscn")
	var instance = test_scene.instantiate()

	add_child(instance)  # Put it into the viewport
