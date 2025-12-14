extends Node

## Attach to each level
## Registers nodes from the level
## Add more when we get more nodes so registration occurs

func _ready():
	print("Initializing level:", self.name)

	# Register this level's nodes to the autoloaded BoardController
	BoardController.register_scene_nodes({
		"slot_map": $TileMapLayer_Board_Slot_Logic,
		"player": $Player,
		"fx_layer": $TileMapLayer_FX,
		"wunderpal": $HUD_Layer/HUD/Wunderpal,
		"wunder_anim": $HUD_Layer/HUD/Wunderpal/AnimationPlayer,
		"viewport": $HUD_Layer/HUD/Wunderpal/Frame/ScreenArea/GameViewport,
	})


	# Initialize the board
	BoardController.build_slot_graph()
	BoardController.snap_player_to_nearest_slot()

	print("Level initialization complete:", self.name)
