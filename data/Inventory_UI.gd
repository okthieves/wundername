extends Control

@onready var use_button: Button     = $Panel/VBoxContainer/UseButton
@onready var drop_button: Button    = $Panel/VBoxContainer/DropButton
@onready var item_list: ItemList    = $Panel/VBoxContainer/ItemList
@onready var add_burger_btn: Button = $Panel/VBoxContainer/AddBurgerButton
@onready var add_scrap_btn: Button  = $Panel/VBoxContainer/AddScrapButton


func _ready():
	hide()  # Start closed

	# Connect signals
	item_list.item_selected.connect(_on_item_selected)
	use_button.pressed.connect(_on_use_pressed)
	drop_button.pressed.connect(_on_drop_pressed)
	add_burger_btn.pressed.connect(_debug_add_burger)
	add_scrap_btn.pressed.connect(_debug_add_scrap)

	refresh_inventory()
	

# ==================================================
#  REFRESH DISPLAY
# ==================================================
func refresh_inventory():
	print("REFRESH INVENTORY CALLED")
	item_list.clear()

	var inv := GameManager.get_inventory()   # Example: {2: 1, 3: 1, 2: 3}
	print("Inventory content:", inv)

	# IMPORTANT:
	# Convert dict → ordered list of keys
	var keys := inv.keys()

	for id in inv.keys():
		var item = ItemDB.get_by_id(id)
		print("ADDING:", item["name"])
		item_list.add_item(item["name"])


# ==================================================
#  SELECTION HELPERS
# ==================================================
func _get_selected_item_id() -> int:
	var sel = item_list.get_selected_items()

	if sel.size() == 0:
		return -1

	var index = sel[0]

	# Match list index → item id
	var inv := GameManager.get_inventory()
	var keys := inv.keys()

	if index >= keys.size():
		return -1

	return keys[index]


func _on_item_selected(index: int) -> void:
	print("Selected inventory index:", index)


# ==================================================
#  BUTTON ACTIONS
# ==================================================
func _on_use_pressed():
	var id := _get_selected_item_id()
	if id == -1:
		print("No item selected.")
		return

	print("Using item:", id)

	var item = ItemDB.get_by_id(id)

	# Example: Use burger
	if item["key"] == "burger":
		GameManager.save_data.player.hp += 15
		print("Healed 15 HP!")

	# Remove one instance
	GameManager.remove_item(id)
	refresh_inventory()


func _on_drop_pressed():
	var id := _get_selected_item_id()
	if id == -1:
		print("No item selected.")
		return

	print("Dropping item:", id)
	GameManager.remove_item(id)
	refresh_inventory()


# ==================================================
#  DEBUG BUTTONS
# ==================================================
func _debug_add_burger():
	GameManager.add_item(2)  # ID 2 is burger
	refresh_inventory()

func _debug_add_scrap():
	GameManager.add_item(3)  # ID 3 is gear_scrap
	refresh_inventory()


# ==================================================
#  OPEN / CLOSE UI
# ==================================================
func open():
	visible = true
	refresh_inventory()

func close():
	hide()
