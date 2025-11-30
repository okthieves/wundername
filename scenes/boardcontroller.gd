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
	var target_cell: Vector2i = player_cell + dir

	print("From:", player_cell, " → To:", target_cell)

	if not slot_ids.has(target_cell):
		print("INVALID. Not a slot.")
		return

	var target_world := slot_map.map_to_local(target_cell)
	player.move_to(target_world)

func _unhandled_input(event):
	if event.is_action_pressed("ui_left"):
		move_direction(Vector2i(-1, 0))
	elif event.is_action_pressed("ui_right"):
		move_direction(Vector2i(1, 0))
	elif event.is_action_pressed("ui_up"):
		move_direction(Vector2i(0, -1))
	elif event.is_action_pressed("ui_down"):
		move_direction(Vector2i(0, 1))
