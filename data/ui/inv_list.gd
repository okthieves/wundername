# FUNCTION: Ask Game Manager for inventory
extends Control

const GRID_SIZE := 12   # 3x4 grid like your mockup

@export var item_grid_cell: PackedScene
@export var empty_grid_cell: PackedScene
@onready var item_container: GridContainer = $ScrollContainer/ItemContainer
@onready var hud: HUD = get_tree().get_first_node_in_group("HUD")

func _ready():
	refresh()
func refresh():
	var inventory := GameManager.get_inventory()
	populate_inventory(inventory)
func populate_inventory(inventory: Dictionary):
	clear_grid()

	var filled := 0

	# 1. Add real items
	for item_id in inventory.keys():
		var amount = inventory[item_id]
		_add_item_cell(item_id, amount)
		filled += 1

	# 2. Add empty slots
	var empty_count = GRID_SIZE - filled
	for i in empty_count:
		_add_empty_cell()
func _add_item_cell(item_id: int, amount: int):
	var cell := item_grid_cell.instantiate()
	item_container.add_child(cell)
	cell.setup(item_id, amount)
func _add_empty_cell():
	var cell = empty_grid_cell.instantiate()
	item_container.add_child(cell)
func clear_grid():
	for child in item_container.get_children():
		child.queue_free()
func _on_item_hovered(item_data: Dictionary, pos: Vector2):
	hud.show_tooltip(item_data, pos)
func _on_item_unhovered():
	hud.hide_tooltip()
