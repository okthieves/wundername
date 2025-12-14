extends Resource
class_name ItemDB

static var ITEMS := {
	1: {
		"id": 1,
		"key": "home_ticket",
		"name": "Home Ticket",
		"type": "key",
		"value": 0,
		"description": "Lets you instantly travel back to station.",
		"icon_path": "res://assets/03_UI/craftpix-net-972304-free-40-loot-icons-pixel-art/1 Icons/Icons_28.png",  # Envelope
	},

	2: {
		"id": 2,
		"key": "burger",
		"name": "Burger",
		"type": "consumable",
		"value": 15,
		"description": "Restores 15 HP.",
		"icon_path": "res://assets/03_UI/craftpix-net-972304-free-40-loot-icons-pixel-art/1 Icons/Icons_19.png",  # Meat
	},

	3: {
		"id": 3,
		"key": "gear_scrap",
		"name": "Salvaged Gear",
		"type": "material",
		"value": 5,
		"description": "Useful for crafting and repairs.",
		"icon_path": "res://assets/03_UI/craftpix-net-972304-free-40-loot-icons-pixel-art/1 Icons/Icons_33.png",  # Mechanism
	},
}

#============================#
#======HELPER FUNCTIONS======#
#============================#

static func get_by_id(id: int) -> Dictionary:
	return ITEMS.get(id, {})

static func get_by_key(key: String) -> Dictionary:
	for item in ITEMS.values():
		if item["key"] == key:
			return item
	return {}

static func get_item_from_id(id: int) -> Dictionary:
	return ITEMS[id]

static func get_icon(id: int) -> Texture2D:
	if not ITEMS.has(id):
		return null
	
	var item = ITEMS[id]
	if not item.has("icon_path") or item["icon_path"] == "":
		return null
	
	var texture = load(item["icon_path"]) as Texture2D
	return texture
