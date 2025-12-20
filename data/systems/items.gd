## Global item database resource.
## Stores static definitions for all items in the game,
## including metadata used by inventory, UI, and gameplay systems.
##
## This is a data-only class and should not contain gameplay logic.
extends Resource
class_name ItemDB


## Dictionary containing all item definitions.
## Each entry is keyed by a unique numeric ID and stores item metadata
## such as name, type, description, and icon path.
##
## Structure:
## {
##   id: {
##     "id": int,
##     "key": String,
##     "name": String,
##     "type": String,
##     "value": int,
##     "description": String,
##     "icon_path": String
##   }
## }
static var ITEMS := {
	1: {
		"id": 1,
		"key": "home_ticket",
		"name": "Home Ticket",
		"type": "key",
		"value": 0,
		"description": "Lets you instantly travel back to station.",
		"icon_path": "res://assets/03_UI/CRAFTPIX_FREE_ICONS/1 Icons/Icons_28.png",  # Envelope
	},

	2: {
		"id": 2,
		"key": "burger",
		"name": "Burger",
		"type": "consumable",
		"value": 15,
		"description": "Restores 15 HP.",
		"icon_path": "res://assets/03_UI/CRAFTPIX_FREE_ICONS/1 Icons/Icons_19.png",  # Meat
	},

	3: {
		"id": 3,
		"key": "gear_scrap",
		"name": "Salvaged Gear",
		"type": "material",
		"value": 5,
		"description": "Useful for crafting and repairs.",
		"icon_path": "res://assets/03_UI/CRAFTPIX_FREE_ICONS/1 Icons/Icons_33.png",  # Mechanism
	},
}


#============================#
#====== HELPER FUNCTIONS ====#
#============================#


## Retrieves an item definition by its numeric ID.
## Returns an empty Dictionary if the ID does not exist.
## @param id The numeric item ID.
## @return Dictionary containing item data, or {} if not found.
static func get_by_id(id: int) -> Dictionary:
	return ITEMS.get(id, {})


## Retrieves an item definition by its string key.
## Performs a linear search across all items.
## @param key The unique string key of the item.
## @return Dictionary containing item data, or {} if not found.
static func get_by_key(key: String) -> Dictionary:
	for item in ITEMS.values():
		if item["key"] == key:
			return item
	return {}


## Retrieves an item definition by ID.
## Assumes the ID exists in the database.
## Use `get_by_id()` for safer access.
## @param id The numeric item ID.
## @return Dictionary containing item data.
static func get_item_from_id(id: int) -> Dictionary:
	return ITEMS[id]


## Loads and returns the icon texture for an item.
## Returns null if the item or icon path is missing.
## @param id The numeric item ID.
## @return Texture2D for the item icon, or null if unavailable.
static func get_icon(id: int) -> Texture2D:
	if not ITEMS.has(id):
		return null
	
	var item = ITEMS[id]
	if not item.has("icon_path") or item["icon_path"] == "":
		return null
	
	var texture = load(item["icon_path"]) as Texture2D
	return texture
