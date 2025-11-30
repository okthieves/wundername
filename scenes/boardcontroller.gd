extends Node

@onready var slot_map: TileMapLayer = $"../TileMapLayer_Board_Slot_Logic"
@onready var player: Node2D = $"../Player"

var slot_ids: Dictionary = {}        # { Vector2i : id }
var id_to_slot: Dictionary = {}      # { id : Vector2i }

func _ready():
	build_slot_graph()
	snap_player_to_nearest_slot()
	print("Slot graph built. Slots:", slot_ids.size())
	print("READY.")
	print("BoardController READY")
	print("Player found? ->", $"Player")
	print("SlotMap found? ->", $"TileMapLayer_Board_Slot_Logic")
	

func build_slot_graph():
	slot_ids.clear()
	id_to_slot.clear()

	var id := 0
	for cell in slot_map.get_used_cells():
		slot_ids[cell] = id
		id_to_slot[id] = cell
		id += 1


func snap_player_to_nearest_slot():
	var cell := slot_map.local_to_map(player.position)
	if not slot_ids.has(cell):
		print("WARNING: Player not on a valid slot. Using 0,0.")
		cell = Vector2i.ZERO

	player.position = slot_map.map_to_local(cell)
	print("Snapped to slot:", cell)


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

	# 🔥 Trigger logic (after move)
	trigger_slot_action(slot_type, target_cell)
	
func _unhandled_input(event):
	if event.is_action_pressed("ui_left"):
		move_direction(Vector2i(-1, 0))
	elif event.is_action_pressed("ui_right"):
		move_direction(Vector2i(1, 0))
	elif event.is_action_pressed("ui_up"):
		move_direction(Vector2i(0, -1))
	elif event.is_action_pressed("ui_down"):
		move_direction(Vector2i(0, 1))


func find_next_slot(start: Vector2i, dir: Vector2i) -> Vector2i:
	var cell := start + dir
	# Move in the direction until we FIND a slot or FAIL
	while slot_ids.has(cell) == false:
		cell += dir
		# Safety check: stop if we wander too far
		if cell.x < -999 or cell.x > 9999 or cell.y < -999 or cell.y > 9999:
			return start  # no valid slot found
	return cell

func get_slot_type(cell: Vector2i) -> String:
	var tile_data := slot_map.get_cell_tile_data(cell)
	if tile_data == null:
		return "none"
	return tile_data.get_custom_data("slot_type")

func trigger_slot_action(slot_type: String, cell: Vector2i):
	match slot_type:
		"shop":
			print("🛒 Shop triggered at", cell)
			# TODO: open shop UI
		"station":
			print("🏠 Home tile at", cell)
			# TODO: heal player / rest
		"battle":
			print("⚔️ Enemy encounter at", cell)
			# TODO: battle intro
		"npc":
			print("⭐ Event tile activated at", cell)
			# TODO: story event or quest
		"quest":
			print("⭐ Event tile activated at", cell)
			# TODO: story event or quest
		"extension":
			print("⭐ Event tile activated at", cell)
			# TODO: story event or quest
		"normal":
			print("Normal tile.")
