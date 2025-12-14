extends Control

@export var item_grid_cell: PackedScene
@onready var item_container: GridContainer = $ScrollContainer/ItemContainer

func _ready():
	refresh()

func refresh():
	var inventory := GameManager.get_inventory()
	populate_inventory(inventory)

func populate_inventory(inventory: Dictionary):
	clear_grid()

	if inventory.is_empty():
		return

	for item_id in inventory.keys():
		var amount = inventory[item_id]
		_add_item_cell(item_id, amount)

func _add_item_cell(item_id: int, amount: int):
	var cell := item_grid_cell.instantiate()
	item_container.add_child(cell)
	cell.setup(item_id, amount)

func clear_grid():
	for child in item_container.get_children():
		child.queue_free()
