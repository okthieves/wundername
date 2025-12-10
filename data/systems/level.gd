extends Node

func _ready():
	print("Initializing level:", self.name)

	# Register this level's nodes to the autoloaded BoardController
	BoardController.register_scene_nodes({
		"slot_map": $TileMapLayer_Board_Slot_Logic,
		"player": $Player,
		"inventory_ui": $UI/Inventory_UI,
		"fx_layer": $TileMapLayer_FX,
		"ui_prompt": $UI/Button_Prompts,
		"wunderpal": $HUD_Layer/HUD/Wunderpal,
		"wunder_anim": $HUD_Layer/HUD/Wunderpal/AnimationPlayer,
		"viewport": $HUD_Layer/HUD/Wunderpal/ScreenArea/GameViewport,
	})

	# 2. Initialize Wunderpal BEFORE the player sees anything
	BoardController.setup_wunderpal()
	# Initialize the board
	BoardController.build_slot_graph()
	BoardController.snap_player_to_nearest_slot()

	print("Level initialization complete:", self.name)
