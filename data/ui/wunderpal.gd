extends SubViewport


# Attached to $HUD/Wunderpal/Frame/ScreenArea/GameViewport
# Loads the appropriate side scroll scene

## Loads the "scene_id" from tile_data to the subviewport
func load_scene(scene_path: String):
	clear()
	var scene = load(scene_path)
	if scene:
		add_child(scene.instantiate())

## Clears the current scene
func clear():
	for c in get_children():
		c.queue_free()
