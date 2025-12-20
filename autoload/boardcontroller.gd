## Global board controller autoload.
## Manages board-grid logic, player movement between slots,
## interaction handling, and transitions into side-scroller scenes.
##
## This script is registered as an Autoload and persists across levels.
extends Node


#region SCENE REFERENCES

## TileMapLayer containing board slot logic and metadata.
## Expected to define slot types and interaction data via custom tile data.
var slot_map: TileMapLayer

## Reference to the board pawn (player piece).
## Must implement a `move_to(Vector2)` method.
var player: Node2D

## Optional TileMapLayer for board effects (highlights, movement FX, etc.).
var fx_layer: TileMapLayer

## Reference to the Wunderpal HUD root control.
var wunderpal: Control

## AnimationPlayer used to animate Wunderpal open/close transitions.
var wunder_anim: AnimationPlayer

## SubViewport used to load and display side-scrolling scenes.
var viewport: SubViewport

#endregion

#region REGISTRATION FROM LEVELS

## Registers scene-specific node references from the active level.
## Called by levels on load to supply required nodes to the controller.
## @param dict Dictionary mapping variable names to node references.
func register_scene_nodes(dict: Dictionary):
	for key in dict.keys():
		self.set(key, dict[key])
	print("[BoardController] Registered scene nodes:", dict.keys())

#endregion

#region GENERAL VARS

## Maps board slot grid positions to unique numeric IDs.
## Used for slot graph traversal and indexing.
var slot_ids: Dictionary = {}        # { Vector2i : int }

## Reverse lookup mapping slot IDs back to grid positions.
var id_to_slot: Dictionary = {}      # { int : Vector2i }

## Whether the inventory UI is currently open.
## (Reserved for future input gating or UI logic.)
var inventory_open = false

#endregion

#region GODOT NATIVE

## Called when the autoload is initialized.
## Scene-specific setup is completed once a level registers its nodes.
func _ready():
	print("[BoardController] Autoload ready.")
	# Will complete initialization once level registers nodes.

#endregion

#region SLOT GRAPH

## Builds a graph of all valid board slots from the slot TileMapLayer.
## Assigns each slot a unique ID for navigation and lookup.
func build_slot_graph():
	if slot_map == null:
		push_error("slot_map is NULL — did level register nodes?")
		return

	slot_ids.clear()
	id_to_slot.clear()

	var id := 0
	for cell in slot_map.get_used_cells():
		slot_ids[cell] = id
		id_to_slot[id] = cell
		id += 1

	print("[BoardController] Slot graph built:", id, "slots")

#endregion

#region SNAP TO GRID

## Snaps the player pawn to the nearest valid board slot.
## Used on level load or recovery from invalid positioning.
func snap_player_to_nearest_slot():
	if player == null or slot_map == null:
		push_error("Cannot snap player — missing player or slot_map.")
		return

	var cell := slot_map.local_to_map(player.position)

	if not slot_ids.has(cell):
		print("WARNING: Player not on a valid slot. Using 0,0.")
		cell = Vector2i.ZERO

	player.position = slot_map.map_to_local(cell)
	print("Snapped player to:", cell)

#endregion

#region PLAYER MOVEMENT

## Moves the player pawn in a grid direction until a valid slot is reached.
## Handles collision with non-walkable slots and triggers slot actions.
## @param dir Direction vector in grid space (e.g. Vector2i.LEFT).
func move_direction(dir: Vector2i):
	if player == null:
		return

	var player_cell: Vector2i = slot_map.local_to_map(player.position)
	var target_cell := find_next_slot(player_cell, dir)

	if target_cell == player_cell:
		return

	# Determine slot type
	var slot_type := get_slot_type(target_cell)

	# Move player pawn
	var target_world := slot_map.map_to_local(target_cell)
	player.move_to(target_world)

	trigger_slot_action(slot_type, player_cell)

#endregion

#region INPUT HANDLING

## Handles board-level input when UI does not consume it.
## Disabled while menus are open.
func _unhandled_input(event):
	if event.is_action_pressed("toggle_wunderpal"):
		match GameManager.state:
			GameManager.GameState.BOARD:
				GameManager.request_toggle_wunderpal()
			GameManager.GameState.MENU_OPEN:
				GameManager.request_toggle_wunderpal()
			GameManager.GameState.SIDESCROLL:
				GameManager.hud.exit_sidescroll()

	if GameManager.state == GameManager.GameState.MENU_OPEN:
		return
	
	if GameManager.state != GameManager.GameState.BOARD:
		return
	
	elif event.is_action_pressed("ui_left"):
		move_direction(Vector2i(-1, 0))
	elif event.is_action_pressed("ui_right"):
		move_direction(Vector2i(1, 0))
	elif event.is_action_pressed("ui_up"):
		move_direction(Vector2i(0, -1))
	elif event.is_action_pressed("ui_down"):
		move_direction(Vector2i(0, 1))
	elif event.is_action_pressed("ui_interact"):
		try_interact()

#endregion

#region FIND NEXT SLOT

## Finds the next valid walkable slot in a given direction.
## Skips empty grid space until a slot is found or bounds are exceeded.
## @param start Starting grid position.
## @param dir Direction to search.
## @return Grid position of the next valid slot or the starting cell.
func find_next_slot(start: Vector2i, dir: Vector2i) -> Vector2i:
	var cell := start + dir

	while not slot_ids.has(cell):
		cell += dir
		if abs(cell.x) > 2000 or abs(cell.y) > 2000:
			return start

	var slot_type := get_slot_type(cell)

	if not is_walkable(slot_type):
		return start

	return cell

#endregion

#region GET SLOT TYPE ETC.

## Retrieves the primary slot type from tile custom data.
func get_slot_type(cell: Vector2i) -> String:
	var tile_data := slot_map.get_cell_tile_data(cell)
	return tile_data.get_custom_data("slot_type") if tile_data else "none"

## Retrieves the interaction subtype for an interact slot.
func get_slot_subtype(cell: Vector2i) -> String:
	var tile_data := slot_map.get_cell_tile_data(cell)
	return tile_data.get_custom_data("interact_subtype") if tile_data else ""

## Retrieves the scene path associated with an interact slot.
func get_slot_scene(cell: Vector2i) -> String:
	var tile_data := slot_map.get_cell_tile_data(cell)
	return tile_data.get_custom_data("scene_path") if tile_data else ""

#endregion

#region SLOT ACTIONS

## Triggers passive behavior when the player lands on a slot.
## Interaction slots are handled separately via explicit input.
func trigger_slot_action(slot_type: String, cell: Vector2i):
	match slot_type:
		"normal":
			return
		"blocked":
			return
		"interact":
			var subtype = get_slot_subtype(cell)
			print(subtype)
			return

#endregion

#region INTERACT

## Attempts to interact with the current slot.
## Only valid on slots marked as interactable.
func try_interact():
	var cell = slot_map.local_to_map(player.position)
	var slot_type = get_slot_type(cell)

	if slot_type != "interact":
		return

	var subtype = get_slot_subtype(cell)
	var scene_path = get_slot_scene(cell)

	handle_interact(subtype, scene_path)

#endregion

#region INTERACTION HANDLING

## Routes interaction logic based on slot subtype.
## Determines whether to open UI or load a side-scroller scene.
func handle_interact(subtype: String, scene_path: String):
	match subtype:
		"shop": open_shop_ui()
		"npc": open_npc_dialogue()
		"quest": open_quest_ui()
		"rune": open_rune_ui()
		"station", "battle", "house", "dungeon":
			open_sidescroller(scene_path)
		_:
			open_sidescroller(scene_path)

#endregion

#region INTERACTION HELPERS

## Opens the shop UI.
func open_shop_ui(): 
	$HUD/ShopUI.show()

## Opens NPC dialogue UI.
func open_npc_dialogue():
	$HUD/DialogueUI.show()

## Opens quest UI.
func open_quest_ui():
	$HUD/QuestUI.show()

## Opens rune interaction UI.
func open_rune_ui():
	pass

## Loads and displays a side-scrolling scene in the SubViewport.
## @param path Path to the scene file to load.
func open_sidescroller(path: String):
	if path == "" or path == null:
		print("ERROR: No scene assigned for this interact tile.")
		return
	GameManager.set_state(GameManager.GameState.SIDESCROLL)

	GameManager.hud.open_sidescroll(path)
	
	var scene = load(path).instantiate()
	viewport.add_child(scene)

	
#endregion

#region WALKABLE

## Determines whether a slot type can be traversed by the player.
func is_walkable(slot_type: String) -> bool:
	match slot_type:
		"wall": return false
		"normal", "interact": return true
		_: return true

#endregion
