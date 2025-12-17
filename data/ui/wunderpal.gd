extends SubViewport


# Attached to $HUD/Wunderpal/Frame/ScreenArea/GameViewport
# Loads the appropriate side scroll scene

func load_scene(scene_path: String):
	clear()
	var scene = load(scene_path)
	if scene:
		add_child(scene.instantiate())

func clear():
	for c in get_children():
		c.queue_free()
