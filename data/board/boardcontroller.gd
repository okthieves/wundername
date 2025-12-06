extends Node

@onready var slot_map: TileMapLayer = $"../TileMapLayer_Board_Slot_Logic"
@onready var player: Node2D = $"../Player"
@onready var inventory_ui = $"../UI/Inventory_UI"
@onready var fx_layer: TileMapLayer = $"../TileMapLayer_FX"
@onready var UI = $"../UI/Button_Prompts"

var slot_ids: Dictionary = {}        # { Vector2i : id }
var id_to_slot: Dictionary = {}      # { id : Vector2i }
var inventory_open = false

func _ready():
	build_slot_graph()
	snap_player_to_nearest_slot()
	print("Slot graph built. Slots:", slot_ids.size())
	print("READY.")
	print("BoardController READY")
	print("Player found? ->", $"../Player")
	print("SlotMap found? ->", $"../TileMapLayer_Board_Slot_Logic")

# --------------------------------------------------------
# BUILD THE SLOT GRAPH
# --------------------------------------------------------
func build_slot_graph():
	slot_ids.clear()
	id_to_slot.clear()

	var id := 0
	for cell in slot_map.get_used_cells():
		slot_ids[cell] = id
		id_to_slot[id] = cell
		id += 1
# --------------------------------------------------------
# SNAP PLAYER TO THE GRID
# --------------------------------------------------------
func snap_player_to_nearest_slot():
	var cell := slot_map.local_to_map(player.position)
	if not slot_ids.has(cell):
		print("WARNING: Player not on a valid slot. Using 0,0.")
		cell = Vector2i.ZERO

	player.position = slot_map.map_to_local(cell)
	print("Snapped to slot:", cell)
# --------------------------------------------------------
# MOVE THE PLAYER // USES (trigger_slot_action) FOR PROMPT
# --------------------------------------------------------
func move_direction(dir: Vector2i):
	var player_cell: Vector2i = slot_map.local_to_map(player.position)

	var target_cell := find_next_slot(player_cell, dir)

	print("Scan result: from", player_cell, "→ next slot:", target_cell)
	
	# if same cell, nothing found
	if target_cell == player_cell:
		print("No valid slot found in that direction.")
		return

	# 🔥 GET TYPE OF TARGET TILE HERE
	var slot_type := get_slot_type(target_cell)
	print("Target slot type:", slot_type)

	# Move player
	var target_world := slot_map.map_to_local(target_cell)
	player.move_to(target_world)
	trigger_slot_action(slot_type,player_cell)
# --------------------------------------------------------
# INPUT HANDLING
# --------------------------------------------------------
func _unhandled_input(event):
	if event.is_action_pressed("ui_left"):
		move_direction(Vector2i(-1, 0))
	elif event.is_action_pressed("ui_right"):
		move_direction(Vector2i(1, 0))
	elif event.is_action_pressed("ui_up"):
		move_direction(Vector2i(0, -1))
	elif event.is_action_pressed("ui_down"):
		move_direction(Vector2i(0, 1))
	if event.is_action_pressed("ui_inventory"):
		toggle_inventory()
	if event.is_action_pressed("ui_interact"):
		try_interact()
# --------------------------------------------------------
# FIND NEXT SLOT FROM CURRENT SLOT // USES (is_walkable) and (get_slot_type)
# --------------------------------------------------------
func find_next_slot(start: Vector2i, dir: Vector2i) -> Vector2i:
	var cell := start + dir

	# 👇 Scan as far as needed
	while slot_ids.has(cell) == false:
		cell += dir

		# safety limit
		if cell.x < -2000 or cell.x > 2000 or cell.y < -2000 or cell.y > 2000:
			return start

	# Found a real slot? — check type
	var slot_type := get_slot_type(cell)
	

	if not is_walkable(slot_type):
		print("Blocked:", slot_type, " at", cell)
		return start

	return cell

# --------------------------------------------------------
# GETTER - SLOT TYPE, SUBTYPE, and SCENE
# --------------------------------------------------------

func get_slot_type(cell: Vector2i) -> String:
	var tile_data := slot_map.get_cell_tile_data(cell)
	
	if tile_data == null:
		return "none"
	return tile_data.get_custom_data("slot_type")

func get_slot_subtype(cell: Vector2i) -> String:
	var tile_data = slot_map.get_cell_tile_data(cell)
	if tile_data == null:
		return ""
	return tile_data.get_custom_data("interact_subtype")

func get_slot_scene(cell: Vector2i) -> String:
	var tile_data = slot_map.get_cell_tile_data(cell)
	if tile_data == null:
		return ""
	return tile_data.get_custom_data("scene_path")

# --------------------------------------------------------
# TRIGGER SLOT ACTIONS
# --------------------------------------------------------
func trigger_slot_action(slot_type: String, cell: Vector2i):
	match slot_type:
		"normal":
			print("This is a normal cell @", cell)
			hide_prompt()
			# Add hide for interact ui menus
			return

		"blocked":
			print("There is wall @", cell)
			hide_prompt()
			# Add hide for interact ui menus
			return

		"interact":
			# DO NOT OPEN ANYTHING AUTOMATICALLY
			var subtype = get_slot_subtype(cell)
			var prompt_text = get_prompt_text(subtype)
			show_prompt(prompt_text)
			print(subtype, " tile here. Press [E] to interact.")
			return
			
# --------------------------------------------------------
# TRY TO INTERACT WITH SLOT
# --------------------------------------------------------
func try_interact():
	var player_cell: Vector2i = slot_map.local_to_map(player.position)

	var slot_type = get_slot_type(player_cell)
	if slot_type != "interact":
		print("No interaction here.")
		return

	var subtype = get_slot_subtype(player_cell)
	var scene_path = get_slot_scene(player_cell)

	print("Interacting with:", subtype)
	handle_interact(subtype, scene_path)
# --------------------------------------------------------
# HANDLE INTERACTION OF SLOT TYPES
# --------------------------------------------------------
func handle_interact(subtype: String, scene_path: String):
	match subtype:
		# --------------------------
		# UI-BASED INTERACTIONS
		# --------------------------
		"shop":
			open_shop_ui()
			return
		"npc":
			open_npc_dialogue()
			return
		"quest":
			open_quest_ui()
			return
		"rune":
			open_rune_ui()
			return
		# --------------------------
		# SIDE-SCROLLER LEVELS
		# --------------------------
		"station", "battle", "house", "dungeon":
			open_sidescroller(scene_path)
			return
		_:  # default: houses, special zones, etc.
			open_sidescroller(scene_path)
# --------------------------------------------------------
# HELPERS FOR INTERACTION
# --------------------------------------------------------
func open_shop_ui():
	$HUD/ShopUI.show()
func open_npc_dialogue():
	$HUD/DialogueUI.show()
func open_quest_ui():
	$HUD/QuestUI.show()
func open_rune_ui():
	pass
func open_sidescroller(path: String):
	if path == "" or path == null:
		print("ERROR: No scene assigned for this interact tile.")
		return

	var scene = load(path).instantiate()
	$HUD/Wunderpal/ScreenArea/GameViewport.add_child(scene)
# --------------------------------------------------------
# GET INTERACT PROMPT TEXT
# --------------------------------------------------------
func get_prompt_text(subtype: String) -> String:
	match subtype:
		"shop":
			return "Press E to open shop"
		"npc":
			return "Press E to talk"
		"quest":
			return "Press E to view quest"
		"station":
			return "Press E to enter station"
		_:
			return "Press E to interact"
# --------------------------------------------------------
# SHOW / HIDE INTERACT TEXT FUNCTIONS
# --------------------------------------------------------
func show_prompt(text: String) -> void:
	if UI:
		UI.text = text
		UI.visible = true
		
func hide_prompt() -> void:
	if UI:
		UI.visible = false





# --------------------------------------------------------
# HANDLE WALKABLE TILES
# --------------------------------------------------------
func is_walkable(slot_type: String) -> bool:
	match slot_type:
		"wall":
			return false
		"normal", "interact":
			return true
		_:
			return true  # default: treat unknown as walkable
# --------------------------------------------------------
# INVENTORY UI VISIBILITY
# --------------------------------------------------------
func toggle_inventory():
	if inventory_open:
		inventory_ui.close()
		inventory_open = false
	else:
		inventory_ui.open()
		inventory_open = true
