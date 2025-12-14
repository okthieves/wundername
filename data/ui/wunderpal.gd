extends SubViewport


# Attached to $HUD/Wunderpal/Frame/ScreenArea/GameViewport
# Loads the test side scroller scene


func _ready():
	# Load the test side-scroller scene
	var test_scene = load("res://scenes/sidescroller/test_scene.tscn")
	var instance = test_scene.instantiate()

	add_child(instance)  # Put it into the viewport
