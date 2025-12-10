extends Node
# BoardController Autoload

# -----------------------------------------------------------
#  SCENE REFERENCES (assigned by level scripts)
# -----------------------------------------------------------
var slot_map: TileMapLayer
var player: Node2D
var inventory_ui
var fx_layer: TileMapLayer
var UI
var wunderpal: Control
var wunder_anim: AnimationPlayer
var viewport: SubViewport

# -----------------------------------------------------------
#  REGISTRATION FROM LEVELS
# -----------------------------------------------------------
func register_scene_nodes(dict: Dictionary):
	for key in dict.keys():
		self.set(key, dict[key])
	print("[BoardController] Registered scene nodes:", dict.keys())

# -----------------------------------------------------------
#  GENERAL VARS
# -----------------------------------------------------------
var slot_ids: Dictionary = {}        # { Vector2i : id }
var id_to_slot: Dictionary = {}      # { id : Vector2i }
var inventory_open = false

# -----------------------------------------------------------
#  WUNDERPAL VARS
# -----------------------------------------------------------
var is_wunderpal_open := false
var wunderpal_open_offset := 0
var wunderpal_closed_offset := 0
var slide_duration := 0.35

# -----------------------------------------------------------
#  GODOT NATIVE
# -----------------------------------------------------------
func _ready():
	print("[BoardController] Autoload ready.")
	# Will complete initialization once level registers nodes.

# -----------------------------------------------------------
#  WUNDERPAL READY
# -----------------------------------------------------------
func setup_wunderpal():
	if wunderpal == null:
		push_warning("Wunderpal is NULL — did you forget to register nodes?")
		return

	# Open position = current offset
	wunderpal_open_offset = wunderpal.position.y

	# Closed position = offscreen bottom
	wunderpal_closed_offset = wunderpal_open_offset + wunderpal.size.y

	wunderpal.position.y = wunderpal_closed_offset
	wunderpal.visible = false

	print("[BoardController] Wunderpal initialized",
		"open =", wunderpal_open_offset,
		"closed =", wunderpal_closed_offset)

# -----------------------------------------------------------
#  SLOT GRAPH
# -----------------------------------------------------------
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

# -----------------------------------------------------------
#  SNAP TO GRID
# -----------------------------------------------------------
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

# -----------------------------------------------------------
#  PLAYER MOVEMENT
# -----------------------------------------------------------
func move_direction(dir: Vector2i):
	if player == null:
		return

	var player_cell: Vector2i = slot_map.local_to_map(player.position)
	var target_cell := find_next_slot(player_cell, dir)

	if target_cell == player_cell:
		return

	# GET TYPE
	var slot_type := get_slot_type(target_cell)

	# Move player
	var target_world := slot_map.map_to_local(target_cell)
	player.move_to(target_world)

	trigger_slot_action(slot_type, player_cell)

# -----------------------------------------------------------
#  INPUT HANDLING
# -----------------------------------------------------------
func _unhandled_input(event):
	# Block board input when Wunderpal is open
	if is_wunderpal_open:
		if event.is_action_pressed("toggle_wunderpal"):
			toggle_wunderpal()
		return  

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

	if event.is_action_pressed("toggle_wunderpal"):
		toggle_wunderpal()

# -----------------------------------------------------------
#  FIND NEXT SLOT
# -----------------------------------------------------------
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

# -----------------------------------------------------------
#  GET SLOT TYPE ETC.
# -----------------------------------------------------------
func get_slot_type(cell: Vector2i) -> String:
	var tile_data := slot_map.get_cell_tile_data(cell)
	return tile_data.get_custom_data("slot_type") if tile_data else "none"

func get_slot_subtype(cell: Vector2i) -> String:
	var tile_data := slot_map.get_cell_tile_data(cell)
	return tile_data.get_custom_data("interact_subtype") if tile_data else ""

func get_slot_scene(cell: Vector2i) -> String:
	var tile_data := slot_map.get_cell_tile_data(cell)
	return tile_data.get_custom_data("scene_path") if tile_data else ""

# -----------------------------------------------------------
#  SLOT ACTIONS
# -----------------------------------------------------------
func trigger_slot_action(slot_type: String, cell: Vector2i):
	match slot_type:
		"normal":
			hide_prompt()
			return
		"blocked":
			hide_prompt()
			return
		"interact":
			var subtype = get_slot_subtype(cell)
			var prompt_text = get_prompt_text(subtype)
			show_prompt(prompt_text)
			return

# -----------------------------------------------------------
#  INTERACT
# -----------------------------------------------------------
func try_interact():
	var cell = slot_map.local_to_map(player.position)
	var slot_type = get_slot_type(cell)

	if slot_type != "interact":
		return

	var subtype = get_slot_subtype(cell)
	var scene_path = get_slot_scene(cell)

	handle_interact(subtype, scene_path)

# -----------------------------------------------------------
# INTERACTION HANDLING
# -----------------------------------------------------------
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

# -----------------------------------------------------------
#  INTERACTION HELPERS
# -----------------------------------------------------------
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
	viewport.add_child(scene)

# -----------------------------------------------------------
#  PROMPT TEXT
# -----------------------------------------------------------
func get_prompt_text(subtype: String) -> String:
	match subtype:
		"shop": return "Press E to open shop"
		"npc": return "Press E to talk"
		"quest": return "Press E to view quest"
		"station": return "Press E to enter station"
		_: return "Press E to interact"

# -----------------------------------------------------------
#  SHOW / HIDE PROMPT
# -----------------------------------------------------------
func show_prompt(text: String):
	if UI:
		UI.text = text
		UI.visible = true

func hide_prompt():
	if UI:
		UI.visible = false

# -----------------------------------------------------------
#  WALKABLE
# -----------------------------------------------------------
func is_walkable(slot_type: String) -> bool:
	match slot_type:
		"wall": return false
		"normal", "interact": return true
		_: return true

# -----------------------------------------------------------
#  INVENTORY
# -----------------------------------------------------------
func toggle_inventory():
	if inventory_open:
		inventory_ui.close()
	else:
		inventory_ui.open()

	inventory_open = !inventory_open

# -----------------------------------------------------------
#  WUNDERPAL TOGGLE
# -----------------------------------------------------------
func toggle_wunderpal():
	slide_wunderpal(!is_wunderpal_open)

# -----------------------------------------------------------
#  WUNDERPAL SLIDE (animation)
# -----------------------------------------------------------
func slide_wunderpal(open: bool):
	is_wunderpal_open = open

	if open:
		wunderpal.visible = true
		wunder_anim.play("open_wunderpal")
	else:
		wunder_anim.play("close_wunderpal")
		await wunder_anim.animation_finished
		wunderpal.visible = false
